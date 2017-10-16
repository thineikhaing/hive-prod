require 'twitter'
require 'tweetstream'
$twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key = "XD8UGiHDUIdRDcdHK8VuOVYpW"
  config.consumer_secret = "leSaoCAO3I47ttPgYVCmzr09wB9FFwhphyn6TWDifemMaTcuaw"
  config.access_token = "1075984819-i2Jc1ZW3xx5KDJ3tiweBATjBVgMBg73q7gYauJN"
  config.access_token_secret = "osAgvYZQYgiVnBSfGAYV9zm5Wgntg2LJ9kyYYUnX1G1p4"
end
