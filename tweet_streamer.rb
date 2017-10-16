ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.join(File.dirname(__FILE__), '.'))
require File.join(root, "config", "environment")

require 'tweetstream'

p "Initializing daemon..."

TweetStream.configure do |config|
  config.consumer_key = "XD8UGiHDUIdRDcdHK8VuOVYpW"
  config.consumer_secret = "leSaoCAO3I47ttPgYVCmzr09wB9FFwhphyn6TWDifemMaTcuaw"
  config.oauth_token = "1075984819-i2Jc1ZW3xx5KDJ3tiweBATjBVgMBg73q7gYauJN"
  config.oauth_token_secret = "osAgvYZQYgiVnBSfGAYV9zm5Wgntg2LJ9kyYYUnX1G1p4"
  config.auth_method        = :oauth
end

daemon = TweetStream::Daemon.new('tracker',
                                 :log_output => true,
                                 :backtrace  => true,
)

daemon.on_inited do
  ActiveRecord::Base.connection.reconnect!
  p "Listening..."
end

daemon.on_error do |message|
  puts "on_error: #{message}"
end

daemon.on_reconnect do |timeout, retries|
  puts "on_reconnect: #{timeout}, #{retries}"
end

daemon.on_limit do |discarded_count|
  puts "on_limit: #{skip_count}"
end


daemon.filter(follow: 1075984819,track: "SMRT_Singapore") do |status|
  # ::Tweet.create_from_status(status)
  #smrt userID 307781209
  #personal userID 1075984819
  ::Tweet.create_from_status(status)
  puts "#{status.text}"

end