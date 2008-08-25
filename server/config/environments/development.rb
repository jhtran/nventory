# Settings specified here will take precedence over those in config/environment.rb

# You have to enable the two caching settings here to get acts_as_audited
# to record entries in development

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
# Besides the acts_as_audited note above, this needs to be set to true
# for now to work around http://dev.rubyonrails.org/ticket/10896, which
# gets triggered by the link_to call in _notes.html.erb file.
#config.cache_classes = false
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
# See note about acts_as_audited above
#config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
