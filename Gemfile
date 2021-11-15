source 'https://rubygems.org'

ruby '2.6.3'
#gem 'rails', :git => 'git://github.com/rails/rails.git', :tag => 'v4.1.0.beta1'
gem 'rails'
gem 'puma'
gem 'sprockets-rails'
gem 'haml-rails'
gem 'rails-backbone'
gem 'pushwoosh'
gem 'google_maps_service'
gem 'google_places'
gem 'geocoder'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem "hirefire-resource"
gem 'devise'
gem 'httparty'

gem 'geoip'

gem 'pusher'
gem 'em-http-request'
gem 'gon'
gem "cloudfiles"
gem 'carrierwave', '~> 1.0'
gem 'carrierwave-base64'
gem 'fog-aws'
gem "koala"
gem 'factual-api'
gem 'obscenity'
gem 'newrelic_rpm', '~> 6.2', '>= 6.2.0.354'
gem 'airbrake'
gem "mini_magick"
gem "encryptor"
gem 'time_difference'
gem 'pg'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder'
gem "rmagick"
gem 'browser' , '0.5.0'
gem 'clockwork'
gem 'aws-sdk', '~> 2'
gem 'jquery-minicolors-rails'
gem 'rqrcode_png'
# gem "loofah-activerecord"
gem 'rack-timeout'
gem 'kaminari'
gem "svy21"
# gem 'rufus-scheduler'
# gem 'rufus-scheduler', '3.2'
gem 'rufus-scheduler', '~> 3.5', '>= 3.5.2'
gem 'gmaps4rails'
gem 'sass'
gem 'sass-rails'
gem 'compass-rails'
gem 'foundation-rails', '5.5.3.2'
gem 'jquery-ui-rails'
gem 'rack-jsonp-middleware',  :require => 'rack/jsonp'
gem 'activerecord-session_store'
gem "hstore_accessor"
gem 'holidays'

gem "puma_worker_killer"
gem "font-awesome-rails"

gem 'sinatra'

gem 'rails_12factor', group: :production

gem 'oauth1'
# gem 'scout_apm'
gem 'twitter'
gem 'tweetstream'

group :production, :staging do
  gem "sprockets-redirect"
end

# gem 'faker', :git => 'https://github.com/stympy/faker.git', :branch => 'master'

gem 'literate_randomizer'

gem 'telegram-bot'
gem 'telegram-bot-types'

group :assets do
  gem 'bourbon'
  gem 'uglifier', '~> 2.6.1'
  gem 'turbo-sprockets-rails4'
end

group :development do

  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-rails', '~> 1.5', require: false
  gem 'capistrano-rbenv', '~> 2.1'
  gem 'capistrano-db-tasks', require: false

  
  gem 'rails_layout'
  gem 'foreman'
  gem 'pivotal_git_scripts'
  gem 'license_finder'
  gem 'derailed'
end

group :development, :test do
  gem 'rspec-rails'
  # gem 'factory_bot_rails'
  gem 'factory_bot'
  gem 'shoulda-matchers'
  # gem 'evergreen'           , :require => 'evergreen/rails' # Run Jasmine JavaScript unit tests, integrate them into Ruby applications.
  gem 'database_cleaner'

end

group :test do
  gem 'capybara', '~> 2.7', '>= 2.7.1'
  # gem 'capybara', git: 'https://github.com/jnicklas/capybara', ref: '7fa75e55420e'
  gem 'guard-rspec'
end

gem 'net-ssh', '>= 6.0.2'
gem 'ed25519', '>= 1.2', '< 2.0'
gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0'