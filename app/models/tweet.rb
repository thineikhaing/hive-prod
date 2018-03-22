class Tweet < ApplicationRecord
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

    Tweet.send_tweet_noti(tweet)
  end

  def self.send_tweet_noti(tweet)
    tags = tweet.hashtags["tags"]
    tags.gsub(/"/, "").split(',')

    sns = Aws::SNS::Client.new
    if Rails.env.development?
      target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti'
    elsif Rails.env.staging?
      target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti'
    else
      target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_P_Broadcast_Noti'
    end

    alert_message = "["+tweet.creator+"] "+tweet.text

    tweet_topic = Topic.find_by_title(tweet.text)
    topic_id = 0
    if tweet_topic.present?
      topic_id = tweet_topic.id
    end

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


    sns.publish(target_arn: target_topic, message: sns_message, message_structure:"json")
  end
end
