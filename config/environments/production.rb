Hive::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  # config.serve_static_files = false
  config.public_file_server.enabled = false


  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  config.cache_store = :memory_store

  config.active_record.raise_in_transactional_callbacks = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { host: "h1ve-staging.herokuapp.com" }

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # SMTP
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = :true
  config.action_mailer.raise_delivery_errors = :true

  ActionMailer::Base.smtp_settings = {
      :address              => "smtp.raydiusapp.com",
      :port                 => "587",
      :domain               => "raydiusapp.com",
      :authentication       => :plain,
      :user_name            => "info@raydiusapp.com",
      :password             => "raydiusadm1n" ,
      :enable_starttls_auto => false
  }
end

# For factual
require 'factual'

# Pusher Development Credentials
# Credentials are not required in Prod mode because Pusher account is linked directly with Heroku

# require 'pusher'
#Pusher.app_id = '65760'
#Pusher.key    = '149e787d80733d128022'
#Pusher.secret = '08febbd6c964685f36da'

# Pusher.app_id = '76230'
# Pusher.key    = '1ec4c02077ddc62c18e9'
# Pusher.secret = 'b89f64a7d3ff1d5a2adc'
require 'pusher'
Pusher.app_id = "91034"
Pusher.key = "dcc808d176ab4ae8d02e"
Pusher.secret = "9cc9d2a3fdd24021a70a"