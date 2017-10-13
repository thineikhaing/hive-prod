namespace :myappname do
  task :tweetstream => :environment do

    require 'tweetstream'
    require 'twitter'

    TweetStream.configure do |config|
      config.consumer_key = "hdMoJNMnJyeGwfkQBnJts4F68"
      config.consumer_secret = "swTNVaTZwt4ykzxX48s2VQv1X6FGjX0Q2WLr3ctF9IrWpGRd3z"
      config.oauth_token = "1075984819-i2Jc1ZW3xx5KDJ3tiweBATjBVgMBg73q7gYauJN"
      config.oauth_token_secret = "osAgvYZQYgiVnBSfGAYV9zm5Wgntg2LJ9kyYYUnX1G1p4"
      config.auth_method        = :oauth
    end

    client = TweetStream::Client.new

    client.follow('1075984819') do |status|

      msg = status.text
      puts msg

    end
  end
end