source 'https://rubygems.org'
ruby "1.9.3"

#gem 'rails', :git => 'git://github.com/rails/rails.git', :tag => 'v4.1.0.beta1'

gem 'rails'                       , '4.1.0' # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'

gem 'thin'                        , '~> 1.5.0'
gem 'sprockets-rails'             , '~> 2.1.0'
gem 'haml-rails'                  , '~> 0.5.3' # Haml-rails provides Haml generators for Rails 3. It also enables Haml as the templating engine for you, so you don't have to screw around in your own application.rb when your Gemfile already clearly indicated what templating engine you have installed. Hurrah.
gem 'rails-backbone'              , '~> 0.9.10' # Quickly setup backbone.js for use with rails 3.1. Generators are provided to quickly get started.

gem 'urbanairship'                , '~> 2.3.3' # Urbanairship is a Ruby library for interacting with the Urban Airship (http://urbanairship.com) API.

gem 'protected_attributes'        , '~> 1.0.7' # Protect attributes from mass assignment
gem 'delayed_job'                              # Delayed_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background. It is a direct extraction from Shopify where the job table is responsible for a multitude of core tasks.
gem 'delayed_job_active_record'             # ActiveRecord backend for Delayed::Job
gem "hirefire-resource"           , '~> 0.3.2' # HireFire enables you to auto-scale your dynos, schedule capacity during specific times of the week, and recover crashed processes.
gem 'devise'                      , '~> 3.2.4' # Flexible authentication solution for Rails with Warden
gem 'httparty'                    , '~> 0.13.1' # Makes http fun! Also, makes consuming restful web services dead easy.
gem 'geocoder'                    , '~> 1.2.0' # Provides object geocoding (by street or IP address), reverse geocoding (coordinates to street address), distance queries for ActiveRecord and Mongoid, result caching, and more. Designed for Rails but works with Sinatra and other Rack frameworks too.
gem 'pusher'                      , '~> 0.12.0' # Wrapper for pusher.com REST api
gem 'em-http-request'             , '~> 1.1.2' # EventMachine based, async HTTP Request client
gem "gon"                         , '~> 5.0.4' # If you need to send some data to your js files and you don't want to do this with long way trough views and parsing - use this force!
gem "cloudfiles"                  , '~> 1.5.0.3' # A Ruby version of the Rackspace Cloud Files API.
gem "carrierwave"                 , '~> 0.10.0' # Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends.
gem "fog"                                       # The Ruby cloud services library. Supports all major cloud providers including AWS, Rackspace, Linode, Blue Box, StormOnDemand, and many others. Full support for most AWS services including EC2, S3, CloudWatch, SimpleDB, ELB, and RDS.
gem "koala"                       , '~> 1.9.0' # Koala is a lightweight, flexible Ruby SDK for Facebook. It allows read/write access to the social graph via the Graph and REST APIs, as well as support for realtime updates and OAuth and Facebook Connect authentication. Koala is fully tested and supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.
gem 'factual-api'                 , '~> 1.3.14' # Factual's official Ruby driver for the Factual public API.
gem 'obscenity'                   , '~> 1.0.2' # Obscenity is a profanity filter gem for Ruby/Rubinius, Rails (through ActiveModel), and Rack middleware
gem 'newrelic_rpm'                , '~> 3.9.1.236' # New Relic is a performance management system, developed by New Relic, Inc (http://www.newrelic.com). New Relic provides you with deep information about the performance of your web application as it runs in production. The New Relic Ruby Agent is dual-purposed as a either a Gem or plugin, hosted on http://github.com/newrelic/rpm/
gem 'airbrake'                    , '~> 3.1.16' # Send your application errors to our hosted service and reclaim your inbox.
gem "mini_magick"                 , '~> 3.7.0' # Manipulate images with minimal use of memory via ImageMagick / GraphicsMagick
gem "encryptor"                   , '~> 1.3.0' # A simple wrapper for the standard ruby OpenSSL library to encrypt and decrypt strings
gem 'time_difference'             , '~> 0.3.2' # TimeDifference is the missing Ruby method to calculate difference between two given time. You can do a Ruby time difference in year, month, week, day, hour, minute, and seconds.
gem 'pg'                          , '~> 0.17.1' # Use postgresql as the database for Active Record
gem 'coffee-rails'                , '~> 4.0.0' # Use CoffeeScript for .js.coffee assets and views
gem 'jquery-rails'                , '~> 2.1.3' # Use jquery as the JavaScript library
gem 'turbolinks'                  , '~> 2.2.2' # Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'jbuilder'                    , '~> 2.0.6' # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "rmagick"                     , :require => 'RMagick' #gem to resize the image
gem 'browser'                     , '~> 0.5.0' # Do some browser detection with Ruby.
gem 'clockwork'                   , :git => "https://github.com/tomykaira/clockwork.git"
gem 'aws-sdk'
gem 'jquery-minicolors-rails'
gem 'rqrcode_png'           , '~> 0.1.2'

gem 'html5'
gem 'xss_terminate', '~> 0.22'

group :assets do
  gem 'sass-rails'                , '>= 4.0.3' # Sass adapter for the Rails asset pipeline.
  gem 'bourbon'                   , '>= 3.0.1' # Bourbon provides a comprehensive framework of sass mixins that are designed to be as vanilla as possible. Meaning they should not deter from the original CSS syntax. The mixins contain vendor specific prefixes for all CSS3 properties for support amongst modern browsers. The prefixes also ensure graceful degradation for older browsers that support only CSS3 prefixed properties.
  gem 'uglifier'                  , '~> 2.5.0' # Use Uglifier as compressor for JavaScript assets

end
group :development do
  gem 'heroku'                    , '~> 3.6.0' # Client library and command-line tool to deploy and manage apps on Heroku.
  gem 'foreman' # Process manager for applications with multiple components
  gem 'pivotal_git_scripts'       , '~> 1.1.4' # These scripts are helpers for managing developer workflow when using git repos hosted on GitHub.
  gem 'license_finder'      , :git => "https://github.com/pivotal/LicenseFinder.git" # Do you know the licenses of all your application's dependencies? What open source software licenses will your business accept? LicenseFinder culls your Gemfile, detects the licenses of the gems in it, and gives you a report that you can act on. If you already know what licenses your business is comfortable with, you can whitelist them, leaving you with an action report of only those dependencies that have licenses that fall outside of the whitelist.
  #gem 'taps', :require => false # has an sqlite dependency, which heroku hates
  #gem 'sqlite3'
end

group :development, :test do
  gem 'rspec-rails'         , '~> 2.14.2' # RSpec for Rails
  #gem 'capybara'            , '~> 1.1.2' # Capybara is an integration testing tool for rack based web applications. It simulates how a user would interact with a website
  gem 'factory_girl_rails'  , '~> 4.4.1' # factory_girl_rails provides integration between factory_girl and rails 3 (currently just automatic factory definition loading)
  gem 'shoulda-matchers'    , '~> 2.6.0' # Making tests easy on the fingers and eyes
  gem 'evergreen'           , :require => 'evergreen/rails' # Run Jasmine JavaScript unit tests, integrate them into Ruby applications.
  gem 'database_cleaner'    , '~> 1.2.0' # Strategies for cleaning databases. Can be used to ensure a clean state for testing.
end

group :test do
  gem 'capybara'
  gem 'guard-rspec'
end
