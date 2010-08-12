# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
CONFIGFILE = RAILS_ROOT + '/' + 'config/nventory.conf'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store
  config.action_controller.session = { :key => '_nventory_session_id' }

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Authorization plugin for role based access control
  # You can override default authorization system constants here.

  # Can be 'object roles' or 'hardwired'
  AUTHORIZATION_MIXIN = "object roles"

  # NOTE : If you use modular controllers like '/admin/products' be sure
  # to redirect to something like '/sessions' controller (with a leading slash)
  # as shown in the example below or you will not get redirected properly
  #
  # This can be set to a hash or to an explicit path like '/login'
  #
  LOGIN_REQUIRED_REDIRECTION = { :controller => '/login', :action => 'login' }
  PERMISSION_DENIED_REDIRECTION = { :controller => '/login', :action => 'login' }

  # The method your auth scheme uses to store the location to redirect back to
  STORE_LOCATION_METHOD = :store_location
  
  # See Rails::Configuration for more options
  config.after_initialize do
    require 'ruport'
    Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
  end
  #require 'ruport/acts_as_reportable'
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
  inflect.irregular 'drive', 'drives'
#   inflect.uncountable %w( fish sheep )
end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below

# some constants we use when highlighting a dom object inside of a relationship section of the page
RELATIONSHIP_HIGHLIGHT_START_COLOR = '#FF8A00'
RELATIONSHIP_HIGHLIGHT_END_COLOR = '#FFF4E6'
RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR = '#FFF4E6'

DEFAULT_SEARCH_RESULT_COUNT = 25


ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :short => '%B %d, %Y'
)

Mime::Type.register "text/config", :config

require 'will_paginate'
require 'fastercsv'
require 'fast_xs'
require 'net/http'
require 'hpricot'
require 'graphviz'
require 'redcloth'
# Needed for offline background jobs (starling/workling)

## Pull the environment specific config settings
confighash = {}
if File.exist?(CONFIGFILE)
  IO.foreach(CONFIGFILE) do |line|
    line.chomp!
    next if (line =~ /^\s*$/);  # Skip blank lines
    next if (line =~ /^\s*#/);  # Skip comments
    key, value = line.split(/\s*=\s*/, 2)
    confighash[key] = value
  end
  confighash['ldap_server'] ? (LDAP_SERVER = confighash['ldap_server']) : (LDAP_SERVER = false)
  confighash['ldap_servers'] ? (LDAP_SERVERS = confighash['ldap_servers'].split(',')) : (LDAP_SERVERS = false)
  confighash['ldap_base'] ? (LDAP_BASE = confighash['ldap_base']) : (LDAP_BASE = false)
  confighash['ldap_dns_name'] ? (LDAP_DNS_NAME = confighash['ldap_dns_name']) : (LDAP_DNS_NAME = false)
  confighash['ldap_email_suffix'] ? (LDAP_EMAIL_SUFFIX = confighash['ldap_email_suffix']) : (LDAP_EMAIL_SUFFIX  = false)
  if confighash['sso_auth_server'] 
    SSO_AUTH_SERVER = confighash['sso_auth_server']
    SSO_AUTH_URL = "https://#{SSO_AUTH_SERVER}/users.xml?login="
    SSO_LOGIN_URL = "https://#{SSO_AUTH_SERVER}/login"
  else
    SSO_AUTH_SERVER = false
    SSO_AUTH_URL = false
    SSO_LOGIN_URL = false
  end
  confighash['sso_proxy_server'] ? (SSO_PROXY_SERVER = confighash['sso_proxy_server']) : (SSO_PROXY_SERVER = false)
  confighash['sso_proxy_port'] ? (SSO_PROXY_PORT = confighash['sso_proxy_port']) : (SSO_PROXY_PORT = false)
  confighash['help_url'] ? (HELP_URL = confighash['help_url']) : (HELP_URL = 'http://sourceforge.net/apps/trac/nventory/wiki')
  confighash['email_suffix'] ? (EMAIL_SUFFIX = confighash['email_suffix']) : (EMAIL_SUFFIX  = 'example.com')
  confighash['mail_from'] ? ($mail_from = confighash['mail_from']) : ($mail_from = "nventory@#{EMAIL_SUFFIX}")
  confighash['prod_users_email'] ? ($prod_users_email= confighash['prod_users_email']) : ($prod_users_email = "nventory@#{EMAIL_SUFFIX}")
  confighash['dev_users_email'] ? ($dev_users_email= confighash['dev_users_email']) : ($dev_users_email = "nventory@#{EMAIL_SUFFIX}")
  confighash['admin_email'] ? ($admin_email = confighash['admin_email']) : ($admin_email = "admin@#{EMAIL_SUFFIX}")
else # if File.exist?(CONFIGFILE)
  LDAP_SERVER = false
  LDAP_SERVERS = false
  LDAP_BASE = false
  LDAP_DNS_NAME = false
  LDAP_EMAIL_SUFFIX  = false
  SSO_AUTH_SERVER = false
  SSO_AUTH_URL = false
  SSO_LOGIN_URL = false
  SSO_PROXY_SERVER = false
  SSO_PROXY_PORT = false
  HELP_URL = 'http://sourceforge.net/apps/trac/nventory/wiki'
  EMAIL_SUFFIX  = 'example.com'
  $mail_from = "nventory@#{EMAIL_SUFFIX}"
  $prod_users_email = "nventory@#{EMAIL_SUFFIX}"
  $dev_users_email = "nventory@#{EMAIL_SUFFIX}"
  $admin_email = "admin@#{EMAIL_SUFFIX}"
end # if File.exist?(CONFIGFILE)

# Email receipients for the exception_notification plugin
ExceptionNotifier.exception_recipients = $admin_email
require 'model_extensions'
ActiveRecord::Base.send(:extend, ModelExtensions)
