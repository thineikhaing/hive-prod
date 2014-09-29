require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'ejs' # Gets rid of "WARN: tilt autoloading 'ejs' in a non thread-safe way; explicit require 'ejs' suggested."

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
#Bundler.require(*Rails.groups)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Hive
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Assets
    config.assets.initialize_on_precompile = false
    config.assets.precompile += %w(web.css web.js mobile.css mobile.js)

    config.action_dispatch.default_headers.merge!({
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Request-Method' => '*'
    })

    config.generators do |g|
      g.factory_girl false
    end
  end
end

module Factual_Const
  Key = "qG4dfx6KUELOXYR3mxdE2o7fXKay7qTQ3zWTnOFx"
  Secret = "yes4DHYok4jefKCSydsfO6NsYPbmvuMSU5ZcRnjR"
end
module Mealbox_key
  Staging_Key= "81e75dccf4934e7224211d5e8096ea41"
  Development_Key = "f3b6eed28269900bc7eea17ebac5e701"
  Production_Key = "e1dff49b39072847a4e1ccad404529e3"
end

module Carmmunicate_key
  Staging_Key= "f8472f0781cf474624915066d4d57da7"
  Development_Key = "58de665af6db2812702682085777a3a8"
  Production_Key = "7a5a7255d7da220dbf612ed874487d8b"
end

module App_Password #constant variable to be used for encryption and decryption
  Key = "rebel4six"
  Length = "8 bytes!"
  Size =1024
end

module Urbanairship_Const
  CM_S_Key = "0NEm0U0jRky2BdqtV6l3GQ"
  CM_S_Secret = "Y7y0bqs4Q-G7aFRmelnS4g"
  CM_S_Master_Secret="8oq947c7QECzlBwtaiCemA"

  #CM_S_Key = "p3JOVu9XS1qzVFyktPS1WA"
  #CM_S_Secret = "Qycncj2tQOSGS6kHQFAGAg"
  #CM_S_Master_Secret="vQNqcpuPRjS3ZE-ICg1d6w"

  CM_P_Key = "vCYzT3kCQimr16p9A-GIMQ"
  CM_P_Secret = "WOnEfbuWRPa9Nvo3t7Mr2Q"
  CM_P_Master_Secret="wSBsSu3xRWOv3fSPZAeEpg"

  CM_D_Key = "qn5A6ujOSaONpcn--rg_NA"
  CM_D_Secret = "k9KS0BvZTnaHxqjf7-Jrpg"
  CM_D_Master_Secret="utulmLxMRL6w7Y-iAwI2fw"
end

module AWS_Link
 AWS_Image_D_Link = "https://hivedevimages.s3.amazonaws.com/"
 AWS_Audio_D_Link = "https://hivedevaudioclips.s3.amazonaws.com/"

 AWS_Image_S_Link = "https://hivestagingimages.s3.amazonaws.com/"
 AWS_Audio_S_Link = "https://hivestagingaudioclipss.s3.amazonaws.com/"

 AWS_Image_P_Link= "https://hiveproductionimages.s3.amazonaws.com/"
 AWS_Audio_P_Link = "https://hiveproductionaudioclips.s3.amazonaws.com/"
end