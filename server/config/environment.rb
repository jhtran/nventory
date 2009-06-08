# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'
@@domain_name = "domain.com"
# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

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

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.after_initialize do
    require 'ruport'
  end
  #require 'ruport/acts_as_reportable'
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

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

# Email receipients for the exception_notification plugin
ExceptionNotifier.exception_recipients = %w(webmaster)

require 'will_paginate'
require 'fastercsv'
require 'fast_xs'
require 'net/http'
require 'hpricot'
require 'graphviz'
# Needed for offline background jobs (starling/workling)
Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
