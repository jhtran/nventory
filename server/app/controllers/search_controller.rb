class SearchController < ApplicationController

  def search(allparams)
    @mainmodel = allparams[:mainmodel]
    @params = allparams[:webparams]
    @special_joins = allparams[:special_joins]
    default_includes = allparams[:default_includes]

    # The index page includes some data from associations.  If we don't
    # include those associations then N SQL calls result as that data is
    # looked up row by row, but using includes does 'eager loading' instead

    # in case passed on the CLI manually, but usually blank at this point, gets set later in parse_*_params
    @includes, process_includes_errors = search_process_includes(@mainmodel, @params[:include])
    compare_includes = @includes.dup
    # get the default includes that are displayed from controller's index_row pages
    if !@params[:format] || @params[:format] == 'html'
      default_includes.each do |key| 
         @includes[key] = {}
      end
    end

    def_attr = @mainmodel.default_search_attribute
    # Set the sort var ; used later in the find query
    if @params['sort'].nil?
      @params['sort'] = @mainmodel.default_search_attribute
      sort = "#{@mainmodel.to_s.tableize}.#{def_attr}"
    elsif @params['sort'] == def_attr.to_s
      sort = "#{@mainmodel.to_s.tableize}.#{def_attr}"
    elsif @params['sort'] == "#{def_attr}_reverse"
      sort = "#{@mainmodel.to_s.tableize}.#{def_attr} DESC"
    elsif @params['sort'] =~ /(.*)_reverse/
      this_model = $1.camelize.constantize
      sort = "#{this_model.to_s.tableize}.#{this_model.default_search_attribute} DESC"
    else
      @params['sort'] =~ /(.*)/
      this_model = $1.camelize.constantize
      sort = "#{this_model.to_s.tableize}.#{this_model.default_search_attribute}"
    end

    @content_column_names = @mainmodel.content_columns.collect { |c| c.name }
    
    # extract searchquery and joins
    local_model_results = parse_local_model_params
    searchquery = local_model_results[:searchquery]
    searchquery_order = local_model_results[:searchquery_order]
    errors = local_model_results[:errors]
    joins = local_model_results[:joins]
    process_includes_errors.each { |error| errors.push(error) }

    # if exclude or 'and' parameter is passed, we'll need to compare two search results to either append or trim off results #
    # See INF-257 - the raw sql way of doing this in one search instead of two, doesn't fit in our method of building a find statement #
    # A few references have pointed to using 'thinking-sphinx' plugin to improve this search controller altogether #
    comparequery = local_model_results[:comparequery]

    logger.info "searchquery" + searchquery.to_yaml
    logger.info "comparequery" + comparequery.to_yaml
    logger.info "includes" + @includes.to_yaml
    logger.info "errors\n" + errors.join("\n")

    ## RUN THE MAIN QUERY ##
    if searchquery.empty?
      # If the user chose to search for deleted objects
        if (@params[:format]) && (@params[:format] == 'xml')
          search_results = @mainmodel.def_scope.find(:all,
                               :include => @includes,
                               :joins => joins.keys.join(' '),
                               :order => sort)
        elsif (@params[:format]) && (@params[:format] == 'csv')
          search_results = @mainmodel.def_scope.report_table(:all,
                               :include => convert_includes(@includes),
                               :joins => joins.keys.join(' '),
                               :order => sort)
        else
          search_results = @mainmodel.def_scope.paginate(:all,
                               :include => @includes,
                               :joins => joins.keys.join(' '),
                               :order => sort,
                               :page => @params[:page])
        end
    else
      # We need to turn that into a valid SQL query, in this case:
      # (nodes.name LIKE ? OR nodes.name LIKE ?) AND statuses.name = ?
      # and an array of search values ['%foo%','%bar%','Active']
      conditions_query = []
      conditions_values = []
      searchquery_order.each do |key|
        value = searchquery[key]
        if value.kind_of? Array
          conditions_tmp = []
          value.each do |v|
            conditions_tmp.push(key)
            conditions_values.push(v)
          end
          conditions_query.push( '(' + conditions_tmp.join(' OR ') + ')' )
        else
          conditions_query.push(key)
          conditions_values.push(value)
        end
      end
      conditions_string = conditions_query.join(' AND ')
      # If the user chose to search for deleted objects
        if (@params[:format]) && (@params[:format] == 'csv')
          search_results = @mainmodel.def_scope.report_table(:all,
                               :include => convert_includes(@includes),
                               :joins => joins.keys.join(' '),
                               :conditions => [ conditions_string, *conditions_values ],
                               :order => sort)
        else
          search_results = @mainmodel.def_scope.find(:all,
                               :include => @includes,
                               :joins => joins.keys.join(' '),
                               :conditions => [ conditions_string, *conditions_values ],
                               :order => sort)
        end
    end # End if searchquery.empty?

    ## RUN THE COMPARISON QUERY ##
    # This comparison block is to REMOVE excluded entries from the final results #
    if !comparequery[:exclude].empty?
      comparequery[:exclude].each_pair do |query,values|
        # build custom include for this query (note assoc and depth not used for anything), ugly but works for now
        assoc, custom_includes, depth = search_for_association(@mainmodel, /(\w+)/.match(query).to_s.to_sym, compare_includes)
        values.each do |value|
          compare_results = @mainmodel.def_scope.find(:all,
                               :include => @includes,
                               :joins => joins.keys.join(' '),
                               :conditions => [ query + " LIKE ?", value ],
                               :order => sort)
          compare_results.each do |result|
            search_results.delete(result) if search_results.include?(result)
          end
        end # values.each do |value|
        custom_includes.clear
      end
    end
    # This comparison block is to ADD 'anded' entries to the final results #
    if !comparequery[:and].empty?
      comparequery[:and].each_pair do |query,values|
        after_results = []
        assoc, custom_includes, depth = search_for_association(@mainmodel, /(\w+)/.match(query).to_s.to_sym, compare_includes)
        values.each do |value|
          compare_results = @mainmodel.def_scope.find(:all,
                               :include => @includes,
                               :joins => joins.keys.join(' '),
                               :conditions => [ query + " LIKE ?", *values ],
                               :order => sort)
          search_results.each do |result|
            if compare_results.include?(result)
              ## For some reason this method loop stops after 75 records..
              #  search_results.delete(result) 
              ## so doing this way instead:
              after_results << result
            end
          end
          search_results = after_results unless after_results.empty? 
        end # values.each do |value|
        custom_includes.clear
      end
    end

    if @params[:csv] == true
      csvobj = {}
      csvobj['object_class'] = @mainmodel
      csvobj['sort'] = sort
      csvobj['conditions_string'] = conditions_string
      csvobj['conditions_values'] = conditions_values
      csvobj['includes'] = @includes
      csvobj['joins'] = joins
    end

    ## FINISHED!  RETURN THE RESULTS OR RESULTS-PAGINATED ##
    results = {}
    results[:includes] = @includes
    results[:errors] = errors
    results[:csvobj] = csvobj
    if (@params[:format] && @params[:format] == 'xml')
      results[:search_results] = search_results
    elsif (@params[:format] && @params[:format] == 'csv')
      results[:search_results] = search_results.as(:csv)
    else
      if search_results.kind_of?(WillPaginate::Collection)
        results[:search_results] = search_results
      else
        results[:search_results] = search_results.paginate(:page => @params[:page])
      end
    end
    return results
  end

  def parse_local_model_params
    searchquery = {}
    comparequery = {}
    comparequery[:exclude] = {}
    comparequery[:and] = {}
    errors = []
    joins = {}
    @params.each do |key, value|
      next if key =~ /^webregex_/
      next if key == 'action'
      next if key == 'csv'
      next if key == 'controller'
      next if key == 'format'
      next if key == 'page'
      next if key == 'sort'
      next if key == 'include'
      ## PART 1 - 'LIKE' SQL QUERIES ##
      if (@content_column_names.include?(key) && !value.empty?)
        search_values = []
        if value.kind_of? Hash
          value.each_value { |v| search_values.push('%' + v + '%') }
        elsif value.kind_of? Array
          value.each { |v| search_values.push('%' + v + '%') }
        # if find webgui 'webregex_*' checkbox tag then conver to REGEXP query
        elsif @params['webregex_' + key]
          searchquery["#{@mainmodel.to_s.tableize}.#{key} REGEXP ?"] = value
        # support for range searches (1..121) is 1 through 121.
        elsif value =~ /\[([\d,-]+)\]/
          match = $1
          rangeobj = []
          match.split(/,/).each do |num|
            if num =~ /\D/
              if num =~ /(\d+)-(\d+)/
                 ($1.to_i..$2.to_i).each do |num| 
                    tmpvalue = value.sub(/\[[\d,-]+\]/, num.to_s)
                    rangeobj.push('%' + tmpvalue + '%')
                 end
              end
            else
              tmpvalue = value.sub(/\[[\d,-]+\]/, num.to_s)
              rangeobj.push('%' + tmpvalue + '%')
            end
          end
          search_values = rangeobj.uniq
        else
          search_values.push('%' + value + '%')
        end
        if !search_values.empty?
           searchquery["#{@mainmodel.to_s.tableize}.#{key} LIKE ?"] = search_values 
        end
      ## PART 2 - EXACT 'IS' or 'IN' SQL QUERIES ##
      elsif key =~ /^exact_(.+)$/ && @content_column_names.include?($1) && !value.empty?
        if value.kind_of? Hash
          searchquery["#{@mainmodel.to_s.tableize}.#{$1} IN (?)"] = value.values
        elsif value.kind_of? Array
          searchquery["#{@mainmodel.to_s.tableize}.#{$1} IN (?)"] = value
        else
          searchquery["#{@mainmodel.to_s.tableize}.#{$1} = ?"] = value
        end
      ## PART 3 - 'REGEXP' SQL QUERIES ##
      elsif key =~ /^regex_(.+)$/ && @content_column_names.include?($1) && !value.empty?
        if value.kind_of? Hash
          searchquery["#{@mainmodel.to_s.tableize}.#{$1} REGEXP (?)"] = value.values
        elsif value.kind_of? Array
          searchquery["#{@mainmodel.to_s.tableize}.#{$1} REGEXP (?)"] = value
        else
          searchquery["#{@mainmodel.to_s.tableize}.#{$1} REGEXP ?"] = value
        end
      ## PART 4 - 'NOT LIKE' SQL QUERIES ##
          ## SUPPLEMENTED BY A SECOND COMPARISON QUERY (SEE INF-257) ##
      elsif key =~ /^exclude_(.+)$/ && @content_column_names.include?($1) && !value.empty? 
        search_values = []
        if value.kind_of? Hash
          value.each_value { |v| search_values.push('%' + v + '%') }
        elsif value.kind_of? Array
          value.each { |v| search_values.push('%' + v + '%') }
        else
          search_values.push('%' + value + '%')
        end
        if !search_values.empty?
           searchquery["#{@mainmodel.to_s.tableize}.#{$1} NOT LIKE ?"] = search_values 
           comparequery[:exclude]["#{@mainmodel.to_s.tableize}.#{$1}"] = search_values 
        end
      ## PART 5 - SECOND COMPARISON QUERY (SEE INF-248 && INF-257) ##
      elsif key =~ /^and_(.+)$/ && @content_column_names.include?($1) && !value.empty? 
        search_values = []
        if value.kind_of? Hash
          value.each_value { |v| search_values.push('%' + v + '%') }
        elsif value.kind_of? Array
          value.each { |v| search_values.push('%' + v + '%') }
        else
          search_values.push('%' + value + '%')
        end
        if !search_values.empty?
           comparequery[:and]["#{@mainmodel.to_s.tableize}.#{$1}"] = search_values 
        end
      ## BONUS -- search_for_assoc doesn't like AUdit because of it's polymorphic nature so this special band-aid in place.
      elsif @mainmodel == Audit && key == 'user_id' && value
        searchquery["user_id = ?"] = value
      elsif !value.empty? 
        # call method parse_assoc_params
        assoc_results = parse_assoc_params(key,value)
        assoc_query = assoc_results[:assoc_query] 
        assoc_comparequery = assoc_results[:assoc_comparequery]
        assoc_errors = assoc_results[:assoc_errors]
        assoc_joins = assoc_results[:assoc_joins]

      ###  NEEDS TO BE STREAMLINED.  WHY MAKE SEARCHQUERY & COMPAREQUERY A ARRAY IN PARSE_ASSOC ###
      ###  ONLY  TO CONVERT BACK TO A HASH HERE? 						###
        # append the key value to the main searchquery hash
        akey, avalue = assoc_query 
        if ((akey && avalue) && (!akey.nil? && !avalue.nil?))
          search_values = []
          if avalue.kind_of? Hash
            avalue.each_value { |v| search_values.push(v) }
          elsif avalue.kind_of? Array
            avalue.each { |v| search_values.push(v) }
          else
            search_values.push(avalue)
          end
          unless search_values.empty?
            searchquery["#{akey}"] = search_values 
          end
        end
        unless assoc_comparequery.nil?
          # append the key value to the main comparequery hash
          assoc_comparequery[:and].each_pair do |k,v|
            if (comparequery[:and][k])
              comparequery[:and][k] << v
            else
              comparequery[:and][k] = v
            end
          end
          assoc_comparequery[:exclude].each_pair do |k,v|
            if (comparequery[:exclude][k])
              comparequery[:exclude][k] << v
            else
              comparequery[:exclude][k] = v
            end
          end
        end

        # append the key value to the main joins hash
        assoc_joins.each_pair do |jkey, jvalue|
          if (jkey && jvalue)
            joins[jkey] = jvalue
          end
        end
        # append to errors 
        assoc_errors.each { |error| errors.push(error) }
      end  # End if (@content_column_names.include?(key) && !value.empty?)
    end # End params.each do |key,value|
    searchquery_order =  searchquery.keys.sort_by { |x| if x =~ /NOT LIKE/i then 2 else 1 end }
    ## FINISH - return the searchquery (ordered)
    local_model_results = {}
    local_model_results[:searchquery] = searchquery
    local_model_results[:comparequery] = comparequery
    local_model_results[:searchquery_order] = searchquery_order
    local_model_results[:errors] = errors
    local_model_results[:joins] = joins
    return local_model_results
  end

  def parse_assoc_params(key, value)
    assoc_results = {}
    searchquery = []
    comparequery = {}
    comparequery[:exclude] = {}
    comparequery[:and] = {}
    errors = []
    ## Filter through and set flags as necssary to the type of query
    search_key = nil
    exact_search = nil
    regex_search = nil
    exclude_search = nil
    and_search = nil
    if (key =~ /^exact_(.+)/)
      search_key = $1
      exact_search = true
    elsif @params["webregex_#{key}"]
      search_key = key
      exact_search = false
      regex_search = true
    elsif (key =~ /^exclude_(.+)/)
      search_key = $1
      exact_search = false
      exclude_search = true
    elsif (key =~ /^and_(.+)/)
      search_key = $1
      exact_search = false
      and_search = true
    else
      search_key = key
      exact_search = false
    end

    assoc = nil
    joins = {}
    ## Build a nested include if necessary and append to @includes for eager loading when doing find
    if (@special_joins.include?(search_key))
      joins[@special_joins[search_key]] = true
    #  assoc = @mainmodel.reflect_on_association(search_key.to_sym)
    end
    assoc, @includes, depth = search_for_association(@mainmodel, search_key.to_sym, @includes)
    if assoc.nil?
      # FIXME: Need better error handling for XML users
      assoc_results[:assoc_errors] = "Ignored invalid search key #{key}"
      assoc_results[:assoc_query] = []
      assoc_results[:assoc_joins] = {}
      logger.info "Ignored invalid search key #{key}"
      return assoc_results
    end

    table_name = search_key.tableize

    search = {}
    # Figure out if the user specified a search column
    # status=inservice
    # status[]=inservice
    if value.kind_of?(String) || value.kind_of?(Array)
      search["#{table_name}.#{assoc.klass.default_search_attribute}"] = value
    # status[1]=inservice
    # status[name]=inservice
    # status[name][1]=inservice
    # status[name][]=inservice
    elsif value.kind_of?(Hash)
      assoc_content_column_names = assoc.klass.content_columns.collect { |c| c.name }
      # This is a bit messy as we have to disambiguate the first two
      # possibilities.
      if value.values.first.kind_of?(String)
        if !assoc_content_column_names.include?(value.keys.first)
          # The first hash key isn't a valid column name in the
          # association, so assume this is like the first example
          search["#{table_name}.#{assoc.klass.default_search_attribute}"] = value.values
        else
          value.each_pair do |search_column,search_value|
            if assoc_content_column_names.include?(search_column)
              search["#{table_name}.#{search_column}"] = search_value
            else
              # FIXME: Need better error handling for XML users
              errors << "Ignored invalid search key #{key}"
              logger.info "Ignored invalid search key #{key}"
            end
          end
        end
      elsif value.values.first.kind_of?(Array)
        value.each_pair do |search_column,search_value|
          if assoc_content_column_names.include?(search_column)
            search["#{table_name}.#{search_column}"] = search_value
          else
            # FIXME: Need better error handling for XML users
            errors << "Ignored invalid search key #{key}"
            logger.info "Ignored invalid search key #{key}"
          end
        end
      elsif value.values.first.kind_of?(Hash)
        value.each_pair do |search_column,search_value|
          if assoc_content_column_names.include?(search_column)
            search["#{table_name}.#{search_column}"] = search_value.values
          else
            # FIXME: Need better error handling for XML users
            errors << "Ignored invalid search key #{key}"
            logger.info "Ignored invalid search key #{key}"
          end
        end
      end
    end
    
    search.each_pair do |skey,svalue|
      if svalue.empty?
        logger.info "Search value for #{skey} is empty"
      else
        if exact_search
          if svalue.kind_of? Array
            searchquery = ["#{skey} IN (?)", svalue]
          else
            searchquery = ["#{skey} = ?", svalue]
          end
        elsif regex_search
          if svalue.kind_of? Array
            searchquery = ["#{skey} REGEXP (?)", svalue]
          else
            searchquery = ["#{skey} REGEXP ?", svalue]
          end
        elsif exclude_search
          if svalue.kind_of? Array
            search_values = []
            svalue.each { |v| search_values.push('%' + v + '%')}
            searchquery = ["#{skey} NOT LIKE ?", search_values]
            comparequery[:exclude][skey] = search_values
          else
            searchquery = ["#{skey} NOT LIKE ?", "%#{svalue}%"]
            comparequery[:exclude][skey] = [svalue]
          end
        elsif and_search
          if svalue.kind_of? Array
            search_values = []
            svalue.each { |v| search_values.push('%' + v + '%')}
            comparequery[:and][skey] = search_values
          else
            comparequery[:and][skey] = [svalue]
          end
        else
          if svalue.kind_of? Array
            search_values = []
            svalue.each { |v| search_values.push('%' + v + '%')}
            searchquery = ["#{skey} LIKE ?", search_values]
          else
            searchquery = ["#{skey} LIKE ?", "%#{svalue}%"]
          end
        end
      end
    end
  
    ## FINISH - RETURN THE ASSOC QUERY RESULTS ##
    assoc_results[:assoc_query] = searchquery
    assoc_results[:assoc_comparequery] = comparequery
    assoc_results[:assoc_errors] = errors
    assoc_results[:assoc_joins] = joins
    return assoc_results
  end # def parse_assoc_params

  # private version of process_includes - differ from the main one in application.rb shared by all other controllers
  def search_process_includes(mainclass, params_data)
    includes = {}
    errors = []
    if params_data
      include_requests = {}
      if params_data.kind_of?(Hash)
        params_data.each do |key,value|
          if value == ''
            include_requests[key] = {}
          else
            include_requests[key] = value
          end
        end
      elsif params_data.kind_of?(Array)
        params_data.each { |p| include_requests[p] = {} }
      else
        include_requests[params_data] = {}
      end

      include_requests.each do |include_request, value|
        assoc = mainclass.reflect_on_association(include_request.to_sym)
        if assoc.nil?
          # FIXME: Need better error handling for XML users
          errors << "Ignored invalid include #{include_request}"
          logger.info "Ignored invalid include #{include_request}"
          next
        else
          # Rails appears to have a bug as of 2.1.1 such that including a
          # has_one, through association causes an exception.  The exception
          # looks like this for future reference:
          # NoMethodError (undefined method `to_ary' for #<Datacenter:0x3aaa1b0>)
          if assoc.macro == :has_one && assoc.options.has_key?(:through)
            # FIXME: Need better error handling for XML users
            errors << "Ignored has_one, through include #{include_request}"
            logger.info "Ignored has_one, through include #{include_request}"
          else
            if !value.empty?
              value, suberrors = search_process_includes(assoc.klass, value)
            end
            includes[include_request.to_sym] = value
          end
        end
      end
    end
    return includes, errors
  end

  def search_for_association(mainclass, target_assoc, includes={}, searched={})
    # Don't go in circles
    return if searched.has_key?(mainclass)
    searched[mainclass] = true
    
    assocmatches = {}
    incmatches = {}
    
    assoc = nil
    depth = nil
    mainclass.reflect_on_all_associations.each do |subassoc|
      # Rails doesn't accept nested :through or :polymorphic associations via include,
      # so skip :through & :polymorphic associations.  We should find the target directly
      # through the chain of associations eventually.
      next if subassoc.options.has_key?(:through)
      next if subassoc.options.has_key?(:polymorphic)
      
      if subassoc.name == target_assoc
        assoc = subassoc
        if !includes.has_key?(assoc.name)
          includes[assoc.name] = {}
        end
        # We found the association directly, i.e. minimum possible depth,
        # so bail and return this one without further searching
        depth = 1
        break
      elsif subassoc.name.to_s.pluralize.to_sym == target_assoc
        assoc = subassoc
        if !includes.has_key?(assoc.name)
          includes[assoc.name] = {}
        end
        # We found the association directly, i.e. minimum possible depth,
        # so bail and return this one without further searching
        depth = 1
        break
      else
        searchinc = nil
        if includes.has_key?(subassoc.name)
          searchinc = includes[subassoc.name]
        else
          searchinc = {}
        end
        searchassoc, searchinc, searchdepth = search_for_association(subassoc.klass, target_assoc, searchinc, searched)
        if !searchassoc.nil?
          searchdepth += 1
          assocmatches[searchdepth] = [] if !assocmatches.has_key?(searchdepth)
          incmatches[searchdepth] = [] if !incmatches.has_key?(searchdepth)
          assocmatches[searchdepth] << searchassoc
          inccopy = includes.dup
          inccopy[subassoc.name] = searchinc
          incmatches[searchdepth] << inccopy
        end
      end
    end
    
    # If we didn't find a minimum depth association then pick the one with
    # the minimum depth from the ones we did find
    if assoc.nil? && !assocmatches.empty?
      depth = assocmatches.keys.min
      assoc = assocmatches[depth].first
      includes = incmatches[depth].first
    end

    # If the depth is 4, that means the model native assoc through has_many cannot be used
    
    [assoc, includes, depth ]
  end

  def gethashkeys(includes)
    master_list = []
    includes.keys.each do |key|
      master_list << key
      if !includes[key].values.empty?
        results = gethashkeys(includes[key])
        results.each { |result| master_list.push(result) }
      end
    end
    master_list
  end
  
  private :search_for_association 
  private :search_process_includes
  private :parse_local_model_params
  private :parse_assoc_params

end
