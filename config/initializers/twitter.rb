require 'twitter'
require 'tweetstream'
$twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key = "0h9yr5YQtXDOaPSAxOM9ugqxS"
  config.consumer_secret = "Wl2NMbnmWPMsnDis1KPxSscdTIwp2n1139nJvWiiM57QqzUWKQ"
  config.access_token = "918754322506162176-cBzO11YTuTvwAEknQ6ga8xgwByYMtkF"
  config.access_token_secret = "QWx9TUcRv54CUITPLYrOC2dwtC5W0R1bKJLBhOTSazqJH"
end
