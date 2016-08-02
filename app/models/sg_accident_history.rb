class SgAccidentHistory < ActiveRecord::Base

  paginates_per 10

  def self.get_incident_and_breakdown
    full_path = 'http://datamall.mytransport.sg/ltaodataservice.svc/IncidentSet'
    url = URI.parse(full_path)
    req = Net::HTTP::Get.new(url.path, initheader = {"accept" =>"application/json", "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==", "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
    con = Net::HTTP.new(url.host, url.port)
    #con.use_ssl = true
    r = con.start {|http| http.request(req)}
    p "get incident list"

    @request_payload = JSON.parse r.body
    @request_payload["d"].each do |data|
      type = data["Type"]
      if type == "Accident" || type == "Vehicle Breakdown" || type == "Heavy Traffic"

        if type == "Vehicle Breakdown"
          type = "VehicleBreakdown"
        elsif type == "Heavy Traffic"
          type = "HeavyTraffic"
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

        sg_accident = SgAccidentHistory.where(message: message).take



        if sg_accident.nil?
          p "add new record"
          SgAccidentHistory.create(type:type,message: message, accident_datetime: accidentDateTIme, latitude:latitude, longitude:longitude, summary:summary )
        end
        if sg_accident.present?

          data = {
              title: sg_accident.message,
              type: sg_accident.type,
              latitude: sg_accident.latitude,
              longitude: sg_accident.longitude,
              accident_datetime: sg_accident.accident_datetime

          }
          Pusher["hive_channel"].trigger_async("train_fault", data)
        end
      end

    end



    # if Rails.env.production?
    #   appID = PushWoosh_Const::RT_P_APP_ID
    #   round_key = RoundTrip_key::Production_Key
    # elsif Rails.env.staging?
    #   appID = PushWoosh_Const::RT_S_APP_ID
    #   round_key = RoundTrip_key::Staging_Key
    # else
    #   appID = PushWoosh_Const::RT_D_APP_ID
    #   round_key = RoundTrip_key::Development_Key
    # end
    #
    # @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}
    #
    # hive_application = HiveApplication.find_by_api_key(round_key)
    # users = User.where("app_data ->'app_id#{hive_application.id}' = '#{hive_application.api_key}'")
    #
    # to_device_id = []
    # user_id = []
    # time_allowance = Time.now - 10.minutes.ago
    # users.each do |u|
    #   if u.check_in_time.present?
    #     time_difference = Time.now - u.check_in_time
    #     unless time_difference.to_i > time_allowance.to_i
    #       p "user data:"
    #       p hash_array = u.data
    #       p u.id
    #
    #       if hash_array.present?
    #         device_id = hash_array["device_id"] if  hash_array["device_id"].present?
    #         to_device_id.push(device_id)
    #         user_id.push(u.id)
    #       end
    #
    #     end
    #   end
    # end
    #
    #
    #
    # sg_accident = SgAccidentHistory.where(notify: false).take
    # if sg_accident.present?
    #
    #   data = {
    #       title: sg_accident.message,
    #       type: sg_accident.type,
    #       latitude: sg_accident.latitude,
    #       longitude: sg_accident.longitude,
    #       accident_datetime: sg_accident.accident_datetime
    #
    #   }
    #   Pusher["hive_channel"].trigger_async("train_fault", data)
    #
    #   sg_accident.notify = true
    #   sg_accident.save
    #     notification_options = {
    #         send_date: "now",
    #         badge: "1",
    #         sound: "default",
    #         content:{
    #             fr:sg_accident.message,
    #             en:sg_accident.message
    #         },
    #         data:{
    #             accident_datetime: sg_accident.accident_datetime,
    #             latitude: sg_accident.latitude,
    #             longitude: sg_accident.longitude,
    #             type: sg_accident.type
    #         },
    #         devices: to_device_id
    #     }
    #
    #   p sg_accident.message
    # else
    #
    #     p "There is no accident or vehicle breakdown yet"
    #
    #     notification_options = {
    #         send_date: "now",
    #         badge: "1",
    #         sound: "default",
    #         content:{
    #             fr:"There is no accident or vehicle breakdown yet",
    #             en:"There is no accident or vehicle breakdown yet"
    #         },
    #         data:{
    #             accident_datetime: Time.now,
    #             latitude: 0,
    #             longitude: 0,
    #             type: ""
    #         },
    #         devices: to_device_id
    #     }
    #
    # end
    #
    # p "App ID"
    # p appID
    # p "user list"
    # p user_id


    # if to_device_id.count > 0 and sg_accident.present?
    #   options = @auth.merge({:notifications  => [notification_options]})
    #   options = {:request  => options}
    #   full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
    #   url = URI.parse(full_path)
    #   req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
    #   req.body = options.to_json
    #   con = Net::HTTP.new(url.host, url.port)
    #   con.use_ssl = true
    #   r = con.start {|http| http.request(req)}
    #   p "pushwoosh message send!"
    # end



  end

end
