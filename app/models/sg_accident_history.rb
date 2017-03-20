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
      if type == "Accident" || type == "Vehicle Breakdown" || type == "Heavy Traffic"
        if type == "Heavy Traffic"
          type = "HeavyTraffic"
        elsif type == "Vehicle Breakdown"
          type = "VehicleBreakdown"
        end

       p "message"
       p message  = data["Message"]  # "(2/2)11:24 Vehicle breakdown on KJE (towards BKE) before Sungei Tengah Exit."
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

        if sg_accident.nil?
          p "add new record"
          SgAccidentHistory.create(type:type,message: message, accident_datetime: accidentDateTIme, latitude:latitude, longitude:longitude, summary:summary )
        end

      end

    end

    self.send_traffic_noti

  end

  def self.send_traffic_noti
    p "send traffic_noti"
    sg_accident = SgAccidentHistory.where(notify: false).take
    if Rails.env.production?
      appID = PushWoosh_Const::RT_P_APP_ID
      hyID = PushWoosh_Const::TE_RTS_APP_ID
      round_key = RoundTrip_key::Production_Key
    elsif Rails.env.staging?
      appID = PushWoosh_Const::RT_S_APP_ID
      hyID = PushWoosh_Const::TE_RTS_APP_ID
      round_key = RoundTrip_key::Staging_Key
    else
      appID = PushWoosh_Const::RT_S_APP_ID
      hyID = PushWoosh_Const::TE_RTS_APP_ID
      round_key = RoundTrip_key::Development_Key
    end

    native_rtauth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}
    auth_hash = {:application  => hyID ,:auth => PushWoosh_Const::API_ACCESS}

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
      time_allowance = Time.now - 30.minutes.ago

      users.each do |u|
        if u.check_in_time.present?
          time_difference = Time.now - u.check_in_time
          if time_difference < time_allowance

            hash_array = u.data
            if hash_array.present?
              device_id = hash_array["device_id"] if  hash_array["device_id"].present?
              to_device_id.push(device_id)
              user_id.push(u.id)
            end

          end

        end

      end

      p "total user near by count"
      p user_id
      p user_id.count

      sg_accident.notify = true
      sg_accident.save
      p sg_accident.message

      notification_options = {
          send_date: "now",
          badge: "1",
          sound: "default",
          content:{
          fr:sg_accident.message,
          en:sg_accident.message
      },
          data:{
          accident_datetime: sg_accident.accident_datetime,
          latitude: sg_accident.latitude,
          longitude: sg_accident.longitude,
          type: sg_accident.type
      },
          devices: to_device_id
      }

      p to_device_id

      if to_device_id.count > 0

        Pushwoosh::PushNotification.new(auth_hash).notify_devices(sg_accident.message, to_device_id, notification_options)
        Pushwoosh::PushNotification.new(native_rtauth).notify_devices(sg_accident.message, to_device_id, notification_options)

        p "pushwoosh"
      end

      startplace = Place.create_place_by_lat_lng(sg_accident.latitude, sg_accident.longitude,User.first)

      topic = Topic.create(title:sg_accident.message, user_id: User.first.id, topic_type: 10 ,start_place_id: startplace.id ,  end_place_id: startplace.id  ,
          topic_sub_type: 0, hiveapplication_id: hive_application.id, place_id: Place.first.id)

      topic.hive_broadcast
      topic.app_broadcast_with_content

    end
  end

end
