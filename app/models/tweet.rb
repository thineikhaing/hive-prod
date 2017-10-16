class Tweet < ApplicationRecord
  def self.create_from_status(status)
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
        posted_at: status.created_at
    )

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


    iphone_notification = {
        aps: {
            alert: tweet.text,
            sound: "default",
            badge: 0,
            extra:  {
                posted_at: tweet.posted_at,
                text: tweet.text,
                tags: tags
            }
        }
    }

    android_notification = {
        data: {
            message:tweet.text,
            badge: 0,
            extra:  {
                posted_at: tweet.posted_at,
                text: tweet.text,
                tags: tags
            }
        }
    }

    sns_message = {
        default: tweet.text,
        APNS_SANDBOX: iphone_notification.to_json,
        APNS: iphone_notification.to_json,
        GCM: android_notification.to_json
    }.to_json


    sns.publish(target_arn: target_topic, message: sns_message, message_structure:"json")

  end
end
