class Trip < ApplicationRecord

  belongs_to :user
  belongs_to :depatures, class_name: "Place", foreign_key: "start_place_id",primary_key: :id
  belongs_to :arrivals, class_name: "Place", foreign_key: "end_place_id",primary_key: :id

  # Setup hstore
  store_accessor :data

  def self.send_alight_noti(message, user_arn)
    if Rails.env.production?
      round_key = RoundTrip_key::Production_Key
    elsif Rails.env.staging?
      round_key = RoundTrip_key::Staging_Key
    else
      round_key = RoundTrip_key::Production_Key
    end

    sns = Aws::SNS::Client.new

    iphone_notification = {
        aps: {
            alert: message,
            sound: "default",
            badge: 0
        }
    }

    android_notification = {
        data: {
            message: message,
            badge: 0
        }
    }

    sns_message = {
        default: message,
        APNS_SANDBOX: iphone_notification.to_json,
        APNS: iphone_notification.to_json,
        GCM: android_notification.to_json
    }.to_json

    begin
      sns.publish(target_arn: user_arn, message: sns_message, message_structure:"json")
    rescue Aws::SNS::Errors::EndpointDisabled
      p "EndpointDisabledException"
    end


  end

end
