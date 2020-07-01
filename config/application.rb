require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Calendarlog
  class Application < Rails::Application
    config.middleware.use ActionDispatch::Cookies
    
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # TZ
    config.time_zone = 'UTC'

    # Logging
    config.lograge.enabled = true
    
    # Email
    config.action_mailer.default_url_options = { host: 'rainfallrecord.info', protocol: 'https' }
    ActionMailer::Base.default from: ENV['EMAIL_USERNAME']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.smtp_settings = {
      :address        => ENV['EMAIL_SERVER_ADDRESS'],
      :port           => ENV['EMAIL_SERVER_PORT'],
      :authentication => :plain,
      :user_name      => ENV['EMAIL_USERNAME'],
      :password       => ENV['EMAIL_PASSWORD'],
      :domain         => ENV['EMAIL_DOMAIN'],
      :enable_starttls_auto => true,
    }

    # Cookies
    # config.action_dispatch.use_cookies_with_metadata = false
    config.action_dispatch.cookies_serializer = :hybrid
  end
end
