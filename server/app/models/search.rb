class Search 
  attr_reader :allparams
  $excludes = %w( action csv controller format page sort include )

  def initialize(allparams={})
    #### DEBUG START ####
    if allparams.empty?
      allparams[:mainmodel] = Node
      allparams[:webparams] = {'name' => 'NodeOne', 'node_groups'=>{'name' => 'NodeGroupOne'}, 'hardware_profile' => {'name' => 'MyString'}, 'datacenter' => {'name' => 'blah'}, 'enable_aliases' => "1" }
    end
    #### DEBUG END ####
    @params = allparams
  end

  def search
    ## 1) DEFAULT VARS ##

    errors = []
    includes = {}
    mainmodel = @params[:mainmodel]
    params = @params[:webparams]
    special_joins = @params[:special_joins]
    # get the default includes that are displayed from controller's index_row pages
    def_attr = mainmodel.default_search_attribute
    sort =  default_sort(mainmodel,def_attr,params['sort'])
    mainmodel_column_names = mainmodel.columns.collect { |c| c.name }
    # determines if aliases table will be looked up for name aliases of model
    params["enable_aliases"] == "1" ? (enable_aliases = true) : (enable_aliases = false)
    params.delete("enable_aliases")

    ## 2) PROCESS LOCAL SEARCH KEYS/INCLUDES ##

    searchkeyhash = process_searchkeys(mainmodel,params)
    RAILS_DEFAULT_LOGGER.info "\n\n *** Searchkeyhash:"
    RAILS_DEFAULT_LOGGER.info searchkeyhash.to_yaml
    requested_includes, tmperrors = requested_includes(mainmodel, params[:include])
    RAILS_DEFAULT_LOGGER.info "\n\n *** Requested includes:"
    RAILS_DEFAULT_LOGGER.info requested_includes.to_yaml
    tmperrors.each { |a| errors << a }
    localresults = local_queries(mainmodel,searchkeyhash[:local_columns])

    ## 3) PROCESS ASSOC SEARCH KEYS/INCLUDES ##

    data = associated_includes(mainmodel, searchkeyhash[:associations])
    associncludes = data[:allincludes]
    associations = data[:allassocs]
    tmperrors = data[:errors]
    and_includes = data[:andincludes]
    exclude_includes = data[:excludeincludes]
    RAILS_DEFAULT_LOGGER.info "\n\n**** ALL:\n"
    RAILS_DEFAULT_LOGGER.info associncludes.to_yaml
    RAILS_DEFAULT_LOGGER.info "\n\n**** AND:\n"
    RAILS_DEFAULT_LOGGER.info and_includes.to_yaml
    RAILS_DEFAULT_LOGGER.info "\n\n**** EXCLUDE:\n"
    RAILS_DEFAULT_LOGGER.info exclude_includes.to_yaml
    associncludes.each_pair{|k,v| includes[k] = v}
    tmperrors.each { |a| errors << a }
    assocresults = assoc_queries(mainmodel,searchkeyhash[:associations],associations)

    ## 4) COMBINE SEARCHQUERY AND SORT ORDER
    searchquery = {}
    localresults[:searchquery].each_pair{|query,values| searchquery[query] = values}
    assocresults[:searchquery].each_pair{|query,values| searchquery[query] = values}
    searchquery_order =  searchquery.keys.sort
    qresults = searchquery_to_s(searchquery_order,searchquery,enable_aliases)
    conditions_string = qresults[:conditions_string]
    conditions_values = qresults[:conditions_values]
    qresults[:includes].each_pair{|k,v| includes[k] = v }

    ## 5) COMPARE QUERY
    # query too complicated to do in one sql query, so run comparison as seperate query and compare it in code (for --and & --exclude)
    and_comparequery = {}
    exclude_comparequery = {}
    localresults[:comparequery][:and].each_pair{|query,values| and_comparequery[query] = values}
    localresults[:comparequery][:exclude].each_pair{|query,values| exclude_comparequery[query] = values}
    assocresults[:comparequery][:and].each_pair{|query,values| and_comparequery[query] = values}
    assocresults[:comparequery][:exclude].each_pair{|query,values| exclude_comparequery[query] = values}
    andquery_results = searchquery_to_s(nil,and_comparequery,enable_aliases)
    and_conditions_string = andquery_results[:conditions_string]
    and_conditions_values = andquery_results[:conditions_values]
    andquery_results[:includes].each_pair{|k,v| and_includes[k] = v }
    excludequery_results = searchquery_to_s(nil,exclude_comparequery,enable_aliases)
    exclude_conditions_string = excludequery_results[:conditions_string]
    exclude_conditions_values = excludequery_results[:conditions_values]
    excludequery_results[:includes].each_pair{|k,v| exclude_includes[k] = v }

    ## 6) PROCESS THE ERRORS
    localresults[:errors].each{|err| errors << err}
    assocresults[:errors].each{|err| errors << err}

    ## 7) RUN THE MAIN FIND
    find_data = {}
    find_data[:conditions_string] = conditions_string
    find_data[:conditions_values] = conditions_values
    find_data[:mainmodel] = mainmodel
    # if we need to do comparequery, no point in getting includes until we have final set of results
    if and_comparequery.empty? && exclude_comparequery.empty?
      if mainmodel.respond_to?('default_includes')
        mainmodel.default_includes.each{|inc| includes[inc] = {} unless includes[inc]} unless params[:format]
      end
      find_data[:iscompareq] = false
      find_data[:includes] = includes 
      find_data[:format] = params[:format]
      find_data[:page] = params[:page]
      find_data[:sort] = sort
    else
      find_data[:iscompareq] = true
      find_data[:joins] = includes 
      find_data[:select] = "#{mainmodel.table_name}.id"
    end
    RAILS_DEFAULT_LOGGER.info "\n\n*** EXECUTING MAIN FIND QUERY\n"
    search_results = findsearch(find_data)
    RAILS_DEFAULT_LOGGER.info "\n\n**** MAIN RESULTS: #{search_results.size}"
  
    ## 8) RUN COMPARISON FIND IF any --and or --exclude, re-using find_data hash
    unless and_conditions_string.empty?
      find_data[:conditions_string] = and_conditions_string
      find_data[:conditions_values] = and_conditions_values
      find_data[:joins] = and_includes
      find_data[:iscompareq] = true
      find_data.delete(:includes) if find_data[:includes]
      RAILS_DEFAULT_LOGGER.info "\n\n*** EXECUTING 'and' FIND QUERY\n"
      and_search_results = findsearch(find_data)
      RAILS_DEFAULT_LOGGER.info "\n\n**** AND RESULTS: #{and_search_results.size}"
      after_results = []
      search_results.each do |result|
        after_results << result if and_search_results.include?(result)
      end
      search_results = after_results
    end
    unless exclude_conditions_string.empty?
      find_data[:conditions_string] = exclude_conditions_string
      find_data[:conditions_values] = exclude_conditions_values
      find_data[:joins] = exclude_includes
      find_data[:iscompareq] = true
      find_data.delete(:includes) if find_data[:includes]
      RAILS_DEFAULT_LOGGER.info "\n\n*** EXECUTING 'exclude' FIND QUERY\n"
      exclude_search_results = findsearch(find_data)
      RAILS_DEFAULT_LOGGER.info "\n\n**** EXCLUDE RESULTS: #{exclude_search_results.size}"
      tmp_results = []
      search_results.each do |result|
        tmp_results << result unless exclude_search_results.include?(result)
      end
      search_results = tmp_results
    end
 
    ## 9) IF COMPARISON, NOW WE GET THE :INCLUDE ACTIVERECORD RESULTS
    unless and_comparequery.empty? && exclude_comparequery.empty?
      result_ids = search_results.collect{|a| a.id}
      if mainmodel.respond_to?('default_includes')
        mainmodel.default_includes.each{|inc| includes[inc] = {} unless includes[inc]} unless params[:format]
      end
      search_results = mainmodel.find(result_ids, :include => includes)
    end
    csvobj = build_csv(find_data) if params[:csv] == true

    ## FINISHED!  RETURN THE RESULTS OR RESULTS-PAGINATED ##
    [ exclude_includes, and_includes ].each{|inclhash| inclhash.each_pair{|k,v| includes[k] = v unless includes[k]}}
    results = {}
    results[:includes] = includes
    results[:requested_includes] = requested_includes
    results[:errors] = errors
    results[:csvobj] = csvobj
    if (params[:format] && params[:format] == 'xml')
      results[:search_results] = search_results
    elsif (params[:format] && params[:format] == 'csv')
      results[:search_results] = search_results.as(:csv)
    else
      if search_results.kind_of?(WillPaginate::Collection)
        results[:search_results] = search_results
      else
        results[:search_results] = search_results.paginate(:page => params[:page])
      end
    end

    return results
  end # def search

  private

    def build_csv(find_data)
      csvobj = {}
      csvobj['object_class'] = find_data[:mainmodel]
      csvobj['sort'] = find_data[:sort]
      csvobj['conditions_string'] = find_data[:conditions_string]
      csvobj['conditions_values'] = find_data[:conditions_values]
      csvobj['includes'] = find_data[:includes]
      return csvobj
    end
  
    def findsearch(find_data)

      conditions_string = find_data[:conditions_string]
      conditions_values = find_data[:conditions_values]
      mainmodel = find_data[:mainmodel]
      includes = find_data[:includes] 
      iscompareq = find_data[:iscompareq]
      joins = find_data[:joins] 
      select = find_data[:select] 
      format = find_data[:format]
      page = find_data[:page]
      sort = find_data[:sort]
      RAILS_DEFAULT_LOGGER.info "FIND INCLUDES:\n" + includes.to_yaml
      if format && format == 'csv'
        search_results = mainmodel.def_scope.report_table(:all,
                             :select => select,
                             :joins => joins,
                             :include => convert_includes(includes),
                             :conditions => [ conditions_string, *conditions_values ],
                             :order => sort)
      elsif (format && format == 'xml') || iscompareq
        search_results = mainmodel.def_scope.find(:all,
                             :select => select,
                             :joins => joins,
                             :include => includes,
                             :conditions => [ conditions_string, *conditions_values ],
                             :order => sort)
      else
        search_results = mainmodel.def_scope.paginate(:all,
                             :select => select,
                             :joins => joins,
                             :include => includes,
                             :conditions => [ conditions_string, *conditions_values ],
                             :page => page,
                             :order => sort)
      end 
      return search_results
    end # def search
  
    def searchquery_to_s(searchquery_order,searchquery,enable_aliases=false)
      conditions_query = []
      conditions_values = []
      results = {}
      results[:includes] = {}
      searchquery_order = searchquery.keys if searchquery_order.nil?
      searchquery_order.each do |key|
        value = searchquery[key]
        if ( key =~ /(\w+).name LIKE \?/i )  && ($1.classify.constantize.reflections.keys.include?(:name_aliases) && enable_aliases )
            results[:includes][:name_aliases] = {}
            key = "#{$1}.name LIKE ? OR name_aliases.name LIKE ?"
            if value.kind_of? Array
              conditions_tmp = []
              value.each do |v|
                conditions_tmp.push(key)
                conditions_values.push(v,v)
              end
              conditions_query.push( '(' + conditions_tmp.join(' OR ') + ')' )
            else
              conditions_query.push(key)
              conditions_values.push(value,value)
            end
        else
          if value.kind_of? Array
            conditions_tmp = []
            value.each do |v|
              conditions_tmp.push(key)
              (key =~ /LIKE/i) ? conditions_values.push(v.gsub(/_/,'\_')) : conditions_values.push(v)
            end
            conditions_query.push( '(' + conditions_tmp.join(' OR ') + ')' )
          else
            conditions_query.push(key)
            (key =~ /LIKE/i) ? conditions_values.push(value.gsub(/_/,'\_')) : conditions_values.push(value)
          end # if value.kind_of? Array
        end # if ( key =~ /(\w+).name LIKE
      end
      conditions_string = conditions_query.join(' AND ')
      results[:conditions_string] = conditions_string
      results[:conditions_values] = conditions_values
      return results
    end
  
    def default_sort(mainmodel,def_attr,sort)
      if sort.nil?
        sort = mainmodel.default_search_attribute
        sort = "#{mainmodel.table_name}.#{def_attr}"
      elsif sort == def_attr.to_s
        sort = "#{mainmodel.table_name}.#{def_attr}"
      elsif sort == "#{def_attr}_reverse"
        sort = "#{mainmodel.table_name}.#{def_attr} DESC"
      elsif sort =~ /(.*)_reverse/
        sort_by = $1
        if mainmodel.column_names.include?(sort_by)
          # is it a local column?
          sort = "#{mainmodel.table_name}.#{sort_by} DESC"
        else
          # otherwise must be a foreign table
          this_model = sort_by.camelize.constantize
          sort = "#{this_model.table_name}.#{this_model.default_search_attribute} DESC"
        end
      else
        sort =~ /(.*)/
        sort_by = $1
        if mainmodel.column_names.include?(sort_by)
          # is it a local column?
          sort = "#{mainmodel.table_name}.#{sort_by}"
        else
          # otherwise must be a foreign table
          this_model = sort_by.camelize.constantize
          sort = "#{this_model.table_name}.#{this_model.default_search_attribute}"
        end
      end
      return sort
    end # def default_sort()

    def recursed_value(data={})
      values = []
      if data.kind_of?(String)
        values << data 
      elsif data.kind_of?(Array)
        data.each{|a| values << a}
      else
        data.each_pair do |k,v| 
          v.kind_of?(Hash) ? (results =  recursed_value(v)) : ( values << v ) 
          results.each{|r| values << r} if results
        end
      end
      return values
    end
  
    def process_searchkeys(localmodel,params)
      local_columns = localmodel.column_names
      attrs = {}
      attrs[:local_columns] = {}
      attrs[:associations] = {}
      params.each do |key, value|
        next if $excludes.include?(key.to_s)
        next if key =~ /^webregex_/
        next if value.empty? || recursed_value(value).to_s.empty?
        # key is a column name, is standard get
        if local_columns.include?(key) && !value.empty?
          attrs[:local_columns][key.to_sym] ||= {} 
          # or possibly regexget if gui issued 'webregexp'
          if params['webregex_' + key]
            attrs[:local_columns][key.to_sym][:regexget] = value
          else
            attrs[:local_columns][key.to_sym][:get] = value
          end # if params['webregex_' + key]
        elsif key =~ /^exact_(.+)$/ && !value.empty?
          if local_columns.include?($1)
            attrs[:local_columns][$1.to_sym] ||= {} 
            attrs[:local_columns][$1.to_sym][:exactget] = value
          else
            attrs[:associations][$1.to_sym] ||= {} 
            attrs[:associations][$1.to_sym][:exactget] = value
          end
        elsif key =~ /^regex_(.+)$/ && !value.empty?
          if local_columns.include?($1)
            attrs[:local_columns][$1.to_sym] ||= {} 
            attrs[:local_columns][$1.to_sym][:regexget] = value
          else
            attrs[:associations][$1.to_sym] ||= {}
            attrs[:associations][$1.to_sym][:regexget] = value
          end
        elsif key =~ /^exclude_(.+)$/ && !value.empty?
          if local_columns.include?($1)
            attrs[:local_columns][$1.to_sym] ||= {}
            attrs[:local_columns][$1.to_sym][:exclude] = value
          else
            attrs[:associations][$1.to_sym] ||= {}
            attrs[:associations][$1.to_sym][:exclude] = value
          end
        elsif key =~ /^and_(.+)$/ && !value.empty?
          if local_columns.include?($1)
            attrs[:local_columns][$1.to_sym] ||= {}
            attrs[:local_columns][$1.to_sym][:and] = value
          else
            attrs[:associations][$1.to_sym] ||= {}
            attrs[:associations][$1.to_sym][:and] = value
          end
        elsif !value.empty?
          attrs[:associations][key.to_sym] ||= {}
          if params['webregex_' + key]
            attrs[:associations][key.to_sym][:regexget] = value
          else
            attrs[:associations][key.to_sym][:get] = value
          end
        end # local_columns.include?(key) && !value.empty?
      end # params.each do |key, value|
  
      return attrs
    end # def process_searchkeys
  
    def requested_includes(mainclass, params_data)
      includes = {}
      errors = []
      include_requests = {}
      return includes, errors unless params_data
      if params_data.kind_of?(Hash)
        params_data.each { |key,value| value == '' ? include_requests[key] = {} : include_requests[key] = value }
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
          RAILS_DEFAULT_LOGGER.info "Ignored invalid include #{include_request}"
          next
        end
        value, suberrors = requested_includes(assoc.klass, value) unless value.empty?
        includes[include_request.to_sym] = value
      end
      return includes, errors
    end
  
    def local_queries(localmodel,searchkeys)
      searchquery = {}
      comparequery = {}
      comparequery[:and] = {}
      comparequery[:exclude] = {}
      errors = []
      joins = {}
      searchkeys.keys.each do |key|
        searchkeys[key].each_pair do |query_type, value|
          next if value.empty? || recursed_value(value).to_s.empty?
          if query_type == :get
              ## PART 1 - 'LIKE' SQL QUERIES ##
            search_values = []
            if value.kind_of? Hash
              value.each_value { |v| search_values.push('%' + v + '%') }
            elsif value.kind_of? Array
              value.each { |v| search_values.push('%' + v + '%') }
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
            searchquery["#{localmodel.table_name}.#{key} LIKE ?"] = search_values unless search_values.empty?
            ## PART 2 - EXACT 'IS' or 'IN' SQL QUERIES ##
          elsif query_type == :exactget
            if value.kind_of? Hash
              searchquery["#{localmodel.table_name}.#{key} IN (?)"] = value.values
            elsif value.kind_of? Array
              searchquery["#{localmodel.table_name}.#{key} IN (?)"] = value
            else
              searchquery["#{localmodel.table_name}.#{key} = ?"] = value
            end
            ## PART 3 - 'REGEXP' SQL QUERIES ##
          elsif query_type == :regexget
            if value.kind_of? Hash
              searchquery["#{localmodel.table_name}.#{key} REGEXP (?)"] = value.values
            elsif value.kind_of? Array
              searchquery["#{localmodel.table_name}.#{key} REGEXP (?)"] = value
            else
              searchquery["#{localmodel.table_name}.#{key} REGEXP ?"] = value
            end
            ## PART 4 - FIRST COMPARISON QUERY - EXCLUDE SQL QUERIES ##
                ## SUPPLEMENTED BY A SECOND COMPARISON QUERY (SEE INF-257) ##
          elsif query_type == :exclude
            search_values = []
            if value.kind_of? Hash
              value.each_value { |v| search_values.push('%' + v + '%') }
            elsif value.kind_of? Array
              value.each { |v| search_values.push('%' + v + '%') }
            else
              search_values.push('%' + value + '%')
            end
            if !search_values.empty?
               comparequery[:exclude]["#{localmodel.table_name}.#{key} LIKE ?"] = search_values
            end
            ## PART 5 - SECOND COMPARISON QUERY (SEE INF-248 && INF-257) ##
          elsif query_type == :and
            search_values = []
            if value.kind_of? Hash
              value.each_value { |v| search_values.push('%' + v + '%') }
            elsif value.kind_of? Array
              value.each { |v| search_values.push('%' + v + '%') }
            else
              search_values.push('%' + value + '%')
            end
            if !search_values.empty?
               comparequery[:and]["#{localmodel.table_name}.#{key} LIKE ?"] = search_values
            end
            ## BONUS -- search_for_assoc doesn't like AUdit because of it's polymorphic nature so this special band-aid in place.
          elsif localmodel == Audit && key == 'user_id' && value
            searchquery["user_id = ?"] = value
          end # if searchkeys[key][:query_type] == :get
        end # searchkeys[key].each_pair 
      end # searchkeys.each do |key|
  
      results = {}
      results[:searchquery] = searchquery
      results[:comparequery] = comparequery
      results[:errors] = errors
      results[:joins] = joins
      return results
    end # def local_queries

    def associated_includes(mainmodel, assochash)
      allincludes = {}
      andincludes = {}
      excludeincludes = {}
      allassocs = {}
      errors = []
      assochash.each_pair do |assockey, value|
        next if value.empty? || recursed_value(value).to_s.empty?
        next if $excludes.include?(assockey.to_s)
        next if assockey =~ /^webregex_/
        unless assockey.kind_of?(Hash)
          assoc, includes, depth = search_for_association(mainmodel, mainmodel, assockey)
          unless assoc
            errors << "Ignored invalid include #{assockey}"
            RAILS_DEFAULT_LOGGER.info "Ignored invalid include #{assockey}"
            next
          end
          allassocs[assockey] = assoc
          includes.each_pair{ |k,v| allincludes[k] = v }
          includes.each_pair{ |k,v| andincludes[k] = v } if value.keys.include?(:and)
          includes.each_pair{ |k,v| excludeincludes[k] = v } if value.keys.include?(:exclude)
        end # unless assockey.kind_of?(Hash)
      end
      data = {}
      data[:allincludes] = allincludes
      data[:allassocs] = allassocs
      data[:errors] = errors
      data[:andincludes] = andincludes
      data[:excludeincludes] = excludeincludes
      return data
    end
  
    def search_for_association(mainmodel, mainclass, target_assoc, includes={}, searched={})
      # Don't go in circles
      return if searched.has_key?(mainclass)
      searched[mainclass] = true
      # see PS-496
      if mainmodel == Node || mainmodel == NodeGroup
        preferred_includes = mainmodel.preferred_includes
        if preferred_includes[target_assoc]
          preferred_assoc = preferred_includes[target_assoc][:assoc]
          prefhash = preferred_includes[target_assoc][:include]
          includes[prefhash.keys.first] = prefhash[prefhash.keys.first]
          return preferred_assoc, includes, 0
        end
      end
  
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
        # rails_auth_plugin adds :users reflection to all models but shouldn't be searched
        next if subassoc.name == :users
  
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
          searchassoc, searchinc, searchdepth = search_for_association(mainmodel, subassoc.klass, target_assoc, searchinc, searched)
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
    end # def search_for_association
  
    def assoc_queries(localmodel,assockeys,associations)
      # default vars
      searchquery = {}
      comparequery = {}
      comparequery[:and] = {}
      comparequery[:exclude] = {}
      errors = []
      joins = {}
      # form the sql based on table relationship and verify column name
      assockeys.each_pair do |assocname,assocvalue|
        assoc = associations[assocname.to_sym]
        if assoc
          table_name = assoc.klass.table_name
          assoc_content_column_names = assoc.klass.content_columns.collect { |c| c.name }
        else
          RAILS_DEFAULT_LOGGER.info "Skipping searchkey #{assocname} - invalid association (not found in includes)"
          next
        end
        search = {}
        assocvalue.each_pair do |query_type, value|
          # Figure out if the user specified a search column
          # status=inservice
          # status[name]=inservice
          if value.kind_of?(String) || value.kind_of?(Array)
            search["#{table_name}.#{assoc.klass.default_search_attribute}"] ||= {} 
            search["#{table_name}.#{assoc.klass.default_search_attribute}"][query_type] = value 
          elsif value.kind_of?(Hash)
            value.each_pair do |skey,sval|
              assoc_content_column_names.include?(skey) ? (search_column = skey) : search_column = assoc.klass.default_search_attribute
              search["#{table_name}.#{search_column}"] ||= {}
              if sval.kind_of?(String) || sval.kind_of?(Array)
                search["#{table_name}.#{skey}"][query_type] = sval
              end
            end
          end # if value.kind_of?(String) || value.kind_of?(Array)
        end # assocvalue.each_pair do |query_type, value|
  
        # form the searchquery based on query type
        search.each_pair do |squery,value|
          value.each_pair do |qtype,svalue|
            next if svalue.empty?
            RAILS_DEFAULT_LOGGER.info "Search value for #{squery} is empty" if svalue.empty?
            if qtype == :exactget
              if svalue.kind_of? Array
                searchquery["#{squery} IN (?)"] = svalue
              else
                searchquery["#{squery} = ?"] = svalue
              end
            elsif qtype == :regexget
              if svalue.kind_of? Array
                searchquery["#{squery} REGEXP (?)"] = svalue
              else
                searchquery["#{squery} REGEXP ?"] = svalue
              end
            elsif qtype == :exclude
              if svalue.kind_of? Array
                search_values = []
                svalue.each { |v| search_values.push('%' + v + '%')}
                comparequery[:exclude]["#{squery} LIKE ?"] = search_values
              else
                comparequery[:exclude]["#{squery} LIKE ?"] = "%#{svalue}%"
              end 
            elsif qtype == :and
              if svalue.kind_of? Array
                search_values = []
                svalue.each { |v| search_values.push('%' + v + '%')}
                comparequery[:and]["#{squery} LIKE ?"] = search_values
              else
                comparequery[:and]["#{squery} LIKE ?"] = "%#{svalue}%"
              end
            elsif qtype == :get
              if svalue.kind_of? Array
                search_values = []
                svalue.each { |v| search_values.push('%' + v + '%')}
                searchquery["#{squery} LIKE ?"] = search_values
              else
                searchquery["#{squery} LIKE ?"] = "%#{svalue}%"
              end
            end # if qtype == :exactget
          end # value.each_pair do |k,v|
        end # search.each_pair do |squery,svalue|
      end # assockeys.each do |key|
  
      results = {}
      results[:searchquery] = searchquery
      results[:comparequery] = comparequery
      results[:errors] = errors
      results[:joins] = joins
      return results
    end # def assoc_queries

end # class Search
