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
      if acct.nil? || !acct.admin
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
  
  # Used by acts_as_audited
  protected
    def current_user
      @user ||= Account.find(session[:account_id]) if session[:account_id]
    end

end
