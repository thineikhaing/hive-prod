ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.join(File.dirname(__FILE__), '.'))
require File.join(root, "config", "environment")

require 'tweetstream'

p "Initializing daemon..."

TweetStream.configure do |config|
  config.consumer_key = "0h9yr5YQtXDOaPSAxOM9ugqxS"
  config.consumer_secret = "Wl2NMbnmWPMsnDis1KPxSscdTIwp2n1139nJvWiiM57QqzUWKQ"
  config.oauth_token = "918754322506162176-cBzO11YTuTvwAEknQ6ga8xgwByYMtkF"
  config.oauth_token_secret = "QWx9TUcRv54CUITPLYrOC2dwtC5W0R1bKJLBhOTSazqJH"
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


daemon.follow(Twitter_Const::SMRT_ID,Twitter_Const::SBS_ID,Twitter_Const::RT_ID) do |status|

  puts "#{status.text}"
  puts "#{status.user.screen_name}"
  puts "#{status.user.id}"
  puts "#{status.user.profile_image_url}"
  puts "#########"
  tweet_user_id = status.user.id

  if (status.text.include? "happy") || (status.text.include? "love") || (status.text.include? "wish") || (status.text.downcase.include? "join us") || (status.text.downcase.include? "our bus guides")|| (status.text.downcase.include? "happy")
    puts "ignore tweet"
  else
    if tweet_user_id.to_i == Twitter_Const::SMRT_ID.to_i
      ::Tweet.create_from_status(status)
      puts "create tweet from smrt and send alert to RT users"
    elsif tweet_user_id.to_i == Twitter_Const::SBS_ID.to_i
      # ::Tweet.create_from_status(status)
      puts "create tweet from sbs and send alert to RT users"
    else
      puts "tweet created by other users"
    end

  end




end
