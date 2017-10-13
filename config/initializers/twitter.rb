require 'twitter'
require 'tweetstream'
$twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key = "hdMoJNMnJyeGwfkQBnJts4F68"
  config.consumer_secret = "swTNVaTZwt4ykzxX48s2VQv1X6FGjX0Q2WLr3ctF9IrWpGRd3z"
  config.access_token = "1075984819-i2Jc1ZW3xx5KDJ3tiweBATjBVgMBg73q7gYauJN"
  config.access_token_secret = "osAgvYZQYgiVnBSfGAYV9zm5Wgntg2LJ9kyYYUnX1G1p4"
end
