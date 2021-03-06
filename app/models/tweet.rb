class Tweet < ApplicationRecord
  scope :expiring_soon, -> {
    date = Date.today >> 1
    where(created_at: ( Date.today-60.days.. Date.today+1.day))
  }
  def self.create_from_status(status)
    p "create tweet from status ::::::"
    hashtags = status.hashtags
    tags  = []
    hashtags.each do |tag|
      tags.push(tag.text)
    end
    p "tags"
    p tags = tags.map(&:inspect).join(',')

    station_tags = Hash.new
    station_tags["tags"] = tags

    tweet = create!(
        text: status.text,
        hashtags: station_tags,
        posted_at: status.created_at,
        creator: status.user.screen_name
    )

    Pusher["hive_channel"].trigger_async("new_tweet", tweet)
    if status.user.screen_name  === 'SBSTransit_Ltd'
      tweet_status = tweet.text.downcase
      if tweet_status.include?("lrt") || tweet_status.include?("nel") || tweet_status.include?("dtl") || tweet_status.include?("punggol lrt") || tweet_status.include?("sengkang lrt")
        Tweet.send_tweet_noti(tweet)
      end
    else
      Tweet.send_tweet_noti(tweet)
    end

  end

  def self.send_tweet_noti(tweet)
    tags = tweet.hashtags["tags"]
    tags.gsub(/"/, "").split(',')

    sns = Aws::SNS::Client.new

    alert_message = "["+tweet.creator+"] "+tweet.text
    tweet_topic = Topic.find_by_title(tweet.text)
    topic_id = 0
    if tweet_topic.present?
      topic_id = tweet_topic.id
    end

    nsl_tweets = []
    ewl_tweets = []
    ccl_tweets = []
    nel_tweets = []
    dtl_tweets = []
    lrt_tweets = []
    lta_tweets = []
    bus_tweets = []

    text = tweet.text
    type = ""

    if text.downcase.include?("nsl") || text.downcase.include?("north-south")
      type = "nsl_tweets"
    elsif text.downcase.include?("ewl") || text.downcase.include?("east-west")
      type = "ewl_tweets"
    elsif text.downcase.include?("ccl")
      type = "ccl_tweets"
    elsif text.downcase.include?("lrt")
      type = "lrt_tweets"
    elsif text.downcase.include?("dtl")
      type = "dtl_tweets"
    elsif text.downcase.include?("nel")
      type = "nel_tweets"
    elsif text.downcase.include?("svcs") || text.downcase.include?("svc") || text.downcase.include?("services") || text.downcase.include?("service")
      type = "bus_tweets"
    else
      type = "lta_tweets"
    end

    p "type :::"
    p type

    iphone_notification = {
        aps: {
            alert: alert_message,
            sound: "default",
            badge: 0,
            extra:  {
                topic_id: topic_id,
                posted_at: tweet.posted_at,
                text: tweet.text,
                tags: tags,
                type: type,
                creator: tweet.creator
            }
        }
    }

    android_notification = {
        data: {
            message:alert_message,
            badge: 0,
            extra:  {
                topic_id: topic_id,
                posted_at: tweet.posted_at,
                text: tweet.text,
                tags: tags,
                creator: tweet.creator
            }
        }
    }

    sns_message = {
        default: alert_message,
        APNS_SANDBOX: iphone_notification.to_json,
        APNS: iphone_notification.to_json,
        GCM: android_notification.to_json
    }.to_json

    to_endpoint_arn= []
    push_tokens = UserPushToken.where(notify: true)
    push_tokens.map{|pt|
      if ! pt.endpoint_arn.nil?
        begin
          sns.publish(target_arn: pt.endpoint_arn, message: sns_message, message_structure:"json")
          p pt.user_id
          p "endpoint arn"
          p pt.endpoint_arn
        rescue
          p "EndpointDisabledException or InvalidParameter"
          p pt.endpoint_arn

            resp = sns.delete_endpoint({
              endpoint_arn: pt.endpoint_arn, # required
            })
            UserPushToken.find_by_endpoint_arn(pt.endpoint_arn).delete
        end
      end
    }

  end
end
