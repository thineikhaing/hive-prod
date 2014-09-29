Hive::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true
  config.serve_static_assets = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Do not compress assets
  config.assets.compress = false

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  config.assets.compile = true
  config.assets.digest = false

  # Devise Mailer
  config.action_mailer.default_url_options = { :host => 'localhost:5000' }

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  ActionMailer::Base.smtp_settings = {
      :address              => "mail.raydiusapp.com",
      :port                 => "587",
      :domain               => "raydiusapp.com",
      :authentication       => :plain,
      :user_name            => "info@raydiusapp.com",
      :password             => "raydiusadm1n",
      :enable_starttls_auto => false
  }
end

# For factual
require 'factual'

# Pusher Development Credentials
# Credentials are not required in Prod mode because Pusher account is linked directly with Heroku
require 'pusher'

Pusher.app_id = '76231'
Pusher.key    = 'd5e72333be1c2e5c6f45'
Pusher.secret = '487a0e829301b6b5b2e8'
