# config/initializers/carrierwave.rb

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'                        # required
  config.fog_credentials = {
  :provider => 'AWS',
  :aws_access_key_id => "AKIAIJMZ5RLXRO6LJHPQ",
  :aws_secret_access_key => "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",
  :region => "ap-southeast-1"
  }

# For testing, upload files to local `tmp` folder.
  if Rails.env.test? || Rails.env.cucumber?
    config.storage = :file
    config.enable_processing = false
    config.root = "#{Rails.root}/tmp"
  else
    config.storage = :fog
  end

  config.cache_dir = "#{Rails.root}/tmp/uploads" # To let CarrierWave work on heroku
  if Rails.env.test? || Rails.env.development?
    config.fog_directory = "hivedeviconimages"
  elsif Rails.env.staging?
    config.fog_directory = "hivestagingiconimages"
  elsif Rails.env.production?
    config.fog_directory = "hiveproductioniconimages"
  end
  config.fog_public = true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
end
