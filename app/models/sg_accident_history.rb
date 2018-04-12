class SgAccidentHistory < ActiveRecord::Base

  paginates_per 10

  def self.get_incident_and_breakdown
    full_path = 'http://datamall2.mytransport.sg/ltaodataservice/TrafficIncidents'
    url = URI.parse(full_path)
    req = Net::HTTP::Get.new(url.path, initheader = {"accept" =>"application/json", "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==", "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
    con = Net::HTTP.new(url.host, url.port)
    #con.use_ssl = true
    r = con.start {|http| http.request(req)}
    p "get incident list"
    @request_payload = JSON.parse r.body

    @request_payload["value"].each do |data|
      type = data["Type"]
      if type == "Accident" || type == "Vehicle breakdown" || type == "Heavy traffic"
        if type == "Heavy Traffic"
          type = "HeavyTraffic"
        elsif type == "Vehicle breakdown"
          type = "VehicleBreakdown"
        end

       message  = data["Message"]  # "(2/2)11:24 Vehicle breakdown on KJE (towards BKE) before Sungei Tengah Exit."
        inc_datetime= message.match(" ").pre_match #(2/2)11:24
        message= message.match(" ").post_match
        inc_date = inc_datetime.scan(/\(([^\)]+)\)/).last.first   # "2/2"
        current_year =  Time.now.strftime("%Y")
        inc_date = inc_date+"/"+current_year
        accidentDate = Date.parse(inc_date).strftime("%d %B %Y")
        inc_time =  inc_datetime.gsub(/\(.*\)/, "")
        accidentDateTIme = DateTime.parse(inc_time).strftime("%H:%M:%S %d-%B-%Y")

        latitude = data["Latitude"]
        longitude=data["Longitude"]
        summary=data["Summary"]

        sg_accident = SgAccidentHistory.where(message: message).take if message.present?

        if Rails.env.production?
          round_key = RoundTrip_key::Production_Key
        elsif Rails.env.staging?
          round_key = RoundTrip_key::Staging_Key
        else
          round_key = RoundTrip_key::Development_Key
        end

        hive_application = HiveApplication.find_by_api_key(round_key)

        if sg_accident.nil?
          p "add new record"
          acc_place = Place.create_place_by_lat_lng(latitude, longitude,User.first)
          sg_accident =SgAccidentHistory.create(type:type,message: message, accident_datetime: accidentDateTIme, latitude:latitude, longitude:longitude, summary:summary ,place_id:acc_place.id)

          # topic = Topic.create(title:message, user_id: User.first.id, topic_type: 10 ,start_place_id: startplace.id , end_place_id: startplace.id  ,
          #     special_type: type, hiveapplication_id: hive_application.id, place_id: startplace.id)

        end

        if(sg_accident.notify == false)
          self.send_traffic_noti(sg_accident)
        end

      end

    end


  end

  def self.send_traffic_noti(accident)
    p "send traffic_noti"
    p sg_accident = accident
    p sg_accident.notify
    # p sg_accident = SgAccidentHistory.where(notify: false).take

    if Rails.env.production?
      round_key = RoundTrip_key::Production_Key
    elsif Rails.env.staging?
      round_key = RoundTrip_key::Staging_Key
    else
      round_key = RoundTrip_key::Production_Key
    end
    p round_key
    hive_application = HiveApplication.find_by_api_key(round_key)

    if sg_accident.present?
      latitude = sg_accident.latitude
      longitude= sg_accident.longitude

      radius = 1 if radius.nil?
      center_point = [latitude.to_f, longitude.to_f]
      box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
      users = User.where(last_known_latitude: box[0] .. box[2], last_known_longitude: box[1] .. box[3])
      users = users.where("app_data ->'app_id#{hive_application.id}' = '#{hive_application.api_key}'")

      to_device_id = []
      user_id = []
      time_allowance = Time.now - 1.day.ago
      to_endpoint_arn = []

      users.each do |u|
        if u.check_in_time.present?
          time_difference = Time.now - u.check_in_time
          if time_difference < time_allowance

            hash_array = u.data
            if hash_array.present?
              device_id = hash_array["device_id"] if  hash_array["device_id"].present?
              endpoint_arn = hash_array["endpoint_arn"] if  hash_array["endpoint_arn"].present?
              to_device_id.push(device_id)
              to_endpoint_arn.push(endpoint_arn)
              user_id.push(u.id)
            end
          end
        end
      end

      p "total user near by count"
      p user_id
      p user_id.count
      p "end point arn"
      p to_endpoint_arn

      sg_accident.notify = true
      sg_accident.save
      p sg_accident.message

      # topic = Topic.find_by_title(sg_accident.message)
      #
      # topic.hive_broadcast
      # topic.app_broadcast_with_content

      accident_topic = Topic.find_by_title(sg_accident.message)
      topic_id = 0
      if accident_topic.present?
        topic_id = accident_topic.id
      end



      if to_endpoint_arn.count > 0

        to_endpoint_arn.each do |arn|

          if arn.present?

            user_arn  = arn
            sns = Aws::SNS::Client.new

            iphone_notification = {
                aps: {
                    alert: sg_accident.message,
                    sound: "default",
                    badge: 0,
                    extra:  {
                        topic_id: topic_id,
                        posted_at: sg_accident.accident_datetime,
                        text: sg_accident.message,
                        creator: "LTA",
                        latitude: sg_accident.latitude,
                        longitude: sg_accident.longitude,
                        type: sg_accident.type
                    }
                }
            }

            android_notification = {
                data: {
                    message: sg_accident.message,
                    badge: 0,
                    extra:  {
                        topic_id: topic_id,
                        posted_at: sg_accident.accident_datetime,
                        text: sg_accident.message,
                        creator: "LTA",
                        latitude: sg_accident.latitude,
                        longitude: sg_accident.longitude,
                        type: sg_accident.type
                    }
                }
            }

            # iphone_notification = {
            #     aps: {
            #         alert: sg_accident.message,
            #         sound: "default",
            #         badge: 0,
            #         extra:  {
            #             topic_id: topic.id,
            #             topic_title: topic.title,
            #             place_name: topic.rtplaces_information[:start_place][:name],
            #             start_place: topic.rtplaces_information[:start_place][:name],
            #             end_place:  topic.rtplaces_information[:end_place][:name],
            #             topic_username: topic.username,
            #             create_at: topic.created_at,
            #             accident_datetime: sg_accident.accident_datetime,
            #             latitude: sg_accident.latitude,
            #             longitude: sg_accident.longitude,
            #             type: sg_accident.type
            #         }
            #     }
            # }

            # android_notification = {
            #     data: {
            #         message: sg_accident.message,
            #         badge: 0,
            #         extra:  {
            #             topic_id: topic.id,
            #             topic_title: topic.title,
            #             place_name: topic.rtplaces_information[:start_place][:name],
            #             start_place: topic.rtplaces_information[:start_place][:name],
            #             end_place:  topic.rtplaces_information[:end_place][:name],
            #             topic_username: topic.username,
            #             create_at: topic.created_at,
            #             accident_datetime: sg_accident.accident_datetime,
            #             latitude: sg_accident.latitude,
            #             longitude: sg_accident.longitude,
            #             type: sg_accident.type
            #         }
            #     }
            # }

            sns_message = {
                default: sg_accident.message,
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
      end


    end
  end

end
