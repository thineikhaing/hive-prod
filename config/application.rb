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

    #config.active_job.queue_adapter = :delayed_job

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
  Development_Key = "3cc83947e0d983b7ab487df4d7136904"
  Staging_Key= "7c64b6ba8eebebb73bcdf605b052562e"
  Production_Key = "d80eab337c8eeba960ecf65772e1f2af"
end

module Carmmunicate_key
  Development_Key = "3cb80528ec41b6ac172739a2729ae5be"
  Staging_Key= "63547bb73e27bc8e55c000e126c2c254"
  Production_Key = "05c4919a87614b59e5b6814b02ceff07"
end

module Favr_key
  Development_Key = "469f789de3555ad7b8e45bab410c370e"
  Staging_Key= "643e879e71eb4f624d49ecd3ef01122f"
  Production_Key = "582045053ce9f2310ee9ab0d2a7217d6"
end

module Socal_key
  Development_Key = "3bb30ce29cf7ed39a9167facb9ca7022"
  Staging_Key = "93dc338faf53138be3b10da1338461a0"
  Production_Key = "89433f46a2f596f3f1c8259e8f262c3e"
end

module App_Password #constant variable to be used for encryption and decryption
  Key = "rebel4six"
  Length = "8 bytes!"
  Size =1024
end

#module Urbanairship_Const
#  CM_S_Dev_Key = "0NEm0U0jRky2BdqtV6l3GQ"
#  CM_S_Dev_Secret = "Y7y0bqs4Q-G7aFRmelnS4g"
#  CM_S_Dev_Master_Secret="8oq947c7QECzlBwtaiCemA"
#
#  CM_S_Adhoc_Key = "p3JOVu9XS1qzVFyktPS1WA"
#  CM_S_Adhoc_Secret = "Qycncj2tQOSGS6kHQFAGAg"
#  CM_S_Adhoc_Master_Secret="vQNqcpuPRjS3ZE-ICg1d6w"
#
#  CM_P_Adhoc_Key = "vCYzT3kCQimr16p9A-GIMQ"
#  CM_P_Adhoc_Secret = "WOnEfbuWRPa9Nvo3t7Mr2Q"
#  CM_P_Adhoc_Master_Secret="wSBsSu3xRWOv3fSPZAeEpg"
#
#  CM_P_Dev_Key = "jgUrWRe6SGGUmU-zixDvbw"
#  CM_P_Dev_Secret = "kXm5DrQQRCSv_GjUGx6ROQ"
#  CM_P_Dev_Master_Secret="H8EFnM6WQmCBjvBFtI9Zdg"
#
#  CM_D_Key = "qn5A6ujOSaONpcn--rg_NA"
#  CM_D_Secret = "k9KS0BvZTnaHxqjf7-Jrpg"
#  CM_D_Master_Secret="utulmLxMRL6w7Y-iAwI2fw"
#
#  FV_S_Key = "LSA3cn4IR1K7Hl96MS1I1w"
#  FV_S_Secret = "bjCQ6p4LRfCuHOTbWyuqHA"
#  FV_S_Master_Secret="kgKRIrkpTsiXp4vUO1Utsg"
#
#  FV_P_Key = "2WOYSZRTRLiyanfEg2PQ2w"
#  FV_P_Secret = "qV5S-fplRUCA78Fk25xThw"
#  FV_P_Master_Secret="4wX2m2ZiSsCiLfR2elX_rw"
#
#  FV_D_Key = "7wgMq0dkSWeqo-TbcBvEyg"
#  FV_D_Secret = "xB8kEzjdT4WeqgEm3CKclQ"
#  FV_D_Master_Secret="1EXyDmHxTNSZRV0raeCthA"
#end


module PushWoosh_Const
  CM_D_APP_ID = "B48C7-FE962"
  CM_S_APP_ID = "82255-61ADD"
  CM_P_APP_ID = "40C8F-B20ED"

  FV_D_APP_ID = "2CA0A-0004F"
  FV_S_APP_ID = "B75D6-0ADFE"
  FV_P_APP_ID = "D37E1-A4130"

  API_ACCESS = "y5dMhjeQ1pcAf3SNnMqy4LBexlqTR0d86p2o3c84NhEajv3Mxsffz8QuEVshTklJ6Qn9JpwVPJKjx0bmsCBn"


end


module AWS_Link
 AWS_Image_D_Link = "https://hivedevimages.s3.amazonaws.com/"
 AWS_Audio_D_Link = "https://hivedevaudioclips.s3.amazonaws.com/"

 AWS_Image_S_Link = "https://hivestagingimages.s3.amazonaws.com/"
 AWS_Audio_S_Link = "https://hivestagingaudioclips.s3.amazonaws.com/"

 AWS_Image_P_Link= "https://hiveproductionimages.s3.amazonaws.com/"
 AWS_Audio_P_Link = "https://hiveproductionaudioclips.s3.amazonaws.com/"
end

module AWS_Bucket
  Image_D = "hivedevimages"
  Audio_D = "hivedevaudioclips"

  Image_S = "hivestagingimages"
  Audio_S = "hivestagingaudioclipss"

  Image_P = "hiveproductionimages"
  Audio_P = "hiveproductionimages"
end