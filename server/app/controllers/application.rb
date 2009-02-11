# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # GET requests with no user agent are probably monitoring agents of some
  # sort (including load balancer health checks) and creating sessions for
  # them just fills up the session table with junk
  session :off, :if => Proc.new { |request| request.env['HTTP_USER_AGENT'].blank? && request.get? }

  # Turn on the exception_notification plugin
  # See environment.rb for the email address(s) to which exceptions are mailed
  include ExceptionNotifiable

  # Turn on the ssl_requirement plugin
  # The login controller uses it to ensure that authentication occurs
  # over SSL.  All other activity that comes in on the SSL side (https)
  # will be redirected to the non-SSL (http) side.
  #include SslRequirement

  # Turn on the acts_as_audited plugin for appropriate models
  audit Account, DatabaseInstance, DatabaseInstanceRelationship,
    Datacenter, DatacenterRackAssignment,
    DatacenterVipAssignment, HardwareProfile,
    IpAddress, NetworkInterface, Node, NodeDatabaseInstanceAssignment,
    NodeGroup, NodeGroupNodeAssignment,
    NodeGroupNodeGroupAssignment, OperatingSystem, Outlet, Rack,
    RackNodeAssignment, Status, Subnet, Vip

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_nventory_session_id'
  
  before_filter :check_authentication, :except => :login
  before_filter :check_authorization, :except => :login
  # Don't log passwords
  filter_parameter_logging "password"
  
  def check_authentication 
    # Always require web UI users to authenticate, so that they're
    # already authenticated if they want to make a change.  This
    # provides for a more seamless user experience.  XML users
    # don't have to authenticate unless they're making a change.
    if params[:format] && params[:format] == 'xml'
      return true if request.get?
    end

    unless session[:account_id] 
      session[:original_uri] = request.request_uri
      flash[:error] = "Please authenticate to access that page."
      redirect_to :controller => "login", :action => "login"
      return false
    end 

    # Give the thumb's up if we didn't find any reason to reject the user
    return true
  end

  def check_authorization
    if !request.get?
      acct = Account.find(session[:account_id])
      if acct.nil? || !acct.admin?
        logger.info "Rejecting user for lack of admin privs"
        if params[:format] && params[:format] == 'xml'
          # Seems like there ought to be a slightly easier way to do this
          errs = ''
          xm = Builder::XmlMarkup.new(:target => errs, :indent => 2)
          xm.instruct!
          xm.errors{ xm.error('You must have admin privileges to make changes') }
          render :xml => errs, :status => :unauthorized
          return false
        else
          flash[:error] = 'You must have admin privileges to make changes'
          begin
            redirect_to :back
          # The rescue syntax here seems odd, but it works
          # http://www.ruby-forum.com/topic/85701
          rescue ::ActionController::RedirectBackError
            # This seems like a reasonable default destination in this case
            redirect_to :controller => "login", :action => "login"
          end
          return false
        end
      end
    end
    # Give the thumb's up if we didn't find any reason to reject the user
    return true
  end
  
  # Controllers punt to this method to implement the field_names action
  def field_names(mainclass)
    fields_xml = ''
    xm = Builder::XmlMarkup.new(:target => fields_xml, :indent => 2)
    xm.instruct!
    xm.field_names{
      # Insert all of our local column names
      mainclass.content_columns.each { |column| xm.field_name("#{column.name}") }

      # Then insert all of the column names from our associations
      mainclass.reflect_on_all_associations.each do |assoc|
        # Don't expose implementation details that aren't meaningful
        # to the user
        next if assoc.name == :audits
        next if assoc.name.to_s =~ /_assignments?$/

        # Not sure yet if I want to handle second-level associations in a special way
        # It doesn't matter to the user for searching, but does potentionally matter
        # if they request an include.
        #if assoc.options.has_key?(:through) && assoc.options[:through].to_s !~ /_assignments$/
        #end
        
        assoc.klass.content_columns.each do |column|
          # If it's the column that we let the user shortcut by just
          # specifying the association (leaving off the column name)
          # then indicate that to the user by including the shortcut.
          # I could be convinced to do this in a more XMLish fashion
          # (i.e. a <field_name_shortcut> element or something) if
          # someone wanted to programatically do something with these.
          # Currently the client just dumps these out to the user so this
          # is sufficient.
          if (assoc.klass.respond_to?('default_search_attribute') &&
            column.name == assoc.klass.default_search_attribute)
            xm.field_name("#{assoc.name}[#{column.name}] (#{assoc.name})")
          else
            xm.field_name("#{assoc.name}[#{column.name}]")
          end
        end
      end
    }

    respond_to do |format|
      format.xml { render :xml => fields_xml }
    end
  end
  
  # We allow the user to request that data from associations be
  # included in the results.  This is really only useful for XML
  # users, as the HTML views will just ignore the extra data.
  def process_includes(mainclass, params_data)
    includes = {}
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
          flash[:error] = "Ignored invalid include #{include_request}"
          logger.info "Ignored invalid include #{include_request}"
          next
        else
          # Rails appears to have a bug as of 2.1.1 such that including a
          # has_one, through association causes an exception.  The exception
          # looks like this for future reference:
          # NoMethodError (undefined method `to_ary' for #<Datacenter:0x3aaa1b0>)
          if assoc.macro == :has_one && assoc.options.has_key?(:through)
            # FIXME: Need better error handling for XML users
            flash[:error] = "Ignored has_one, through include #{include_request}"
            logger.info "Ignored has_one, through include #{include_request}"
          else
            if !value.empty?
              value = process_includes(assoc.klass, value)
            end
            includes[include_request.to_sym] = value
          end
        end
      end
    end
    includes
  end
  
  # Recursively search 'mainclass' for an association with a name matching
  # 'target_assoc'.  Returns the association that is closest to mainclass
  # in the association tree, a copy of the includes hash that is passed in
  # with the necessary hierarchy of assocations inserted so that a call to
  # 'find' with those includes could query against that association, and the
  # depth or distance in number of associations between mainclass and the
  # selected assocation.
  # For example, if mainclass were Node and target_assoc were
  # :hardware_profile then the :hardware_profile association would be
  # returned and includes would be populated with { :hardware_profile => {} }
  # Likewise, if mainclass were Node and target_assoc were :datacenter then
  # the :datacenter_rack_assignment association to Datacenter would be
  # returned (this method having recursively descended the
  # Node->RackNodeAssignment->Rack->DatacenterRackAssignment assocations
  # to find that association) and includes would be populated with
  # {:rack_node_assignment => {:rack => {:datacenter_rack_assignment => {:datacenter => {}}}}}
  # Note that the user may pass us an already partially populated includes
  # hash, so we need to be careful to insert any includes we add without
  # removing any that may already be in the hash structure.
  # FIXME: acts_as_paranoid doesn't insert 'deleted_at IS NULL'-type
  # conditions on the includes when we pass them to find, so we should
  # consider having this method build up a list of conditions that we can
  # pass to find along with the includes.
  def search_for_association(mainclass, target_assoc, includes={}, searched={})
    # Audit doesn't respond well to our probing
    return if mainclass == Audit
    # Nor does Comment
    return if mainclass == Comment
    
    # Don't go in circles
    return if searched.has_key?(mainclass)
    searched[mainclass] = true
    
    assocmatches = {}
    incmatches = {}
    
    assoc = nil
    depth = nil
    mainclass.reflect_on_all_associations.each do |subassoc|
      # Rails doesn't accept nested :through associations via include,
      # so skip :through associations.  We should find the target directly
      # through the chain of associations eventually.
      next if subassoc.options.has_key?(:through)
      
      if subassoc.name == target_assoc
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
    
    [assoc, includes, depth]
  end

  # find and to_xml take their :include options in different formats
  # find wants:
  # :include => { :rack => { :datacenter_rack_assignment => :datacenter } }
  # or this (which is what we use because it is easier to generate recursively)
  # :include => { :rack => { :datacenter_rack_assignment => { :datacenter => {} } } }
  # to_xml wants:
  # :include => { :rack => { :include => { :datacenter_rack_assignment => { :include => { :datacenter => {} } } } } }
  # This method takes the find format and returns the to_xml format
  def convert_includes(includes)
    includes.each do |key, value|
      includes[key] = { :include => convert_includes(value) }
    end
    includes
  end
  
  # Used by acts_as_audited
  protected
    def current_user
      @user ||= Account.find(session[:account_id]) if session[:account_id]
    end

end
