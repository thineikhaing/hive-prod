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
      end

    end

    p "Push Woosh Authentication"
    if Rails.env.production?
      appID = PushWoosh_Const::RT_D_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::RT_D_APP_ID
    else
      appID = PushWoosh_Const::RT_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}


    @users_to_push = []
    @to_device_id = []
    @users = User.all
    time_allowance = Time.now - 10.minutes.ago
    @users.each do |u|
      if u.check_in_time.present?
        time_difference = Time.now - u.check_in_time
        unless time_difference.to_i > time_allowance.to_i
          @users_to_push.push(u)
        end
      end
    end

    @users_to_push.each do |u|
      user= User.find_by_id(u)
      if user.data.present?
        hash_array = user.data
        device_id = hash_array["device_id"] if  hash_array["device_id"].present?
        @to_device_id.push(device_id)
      end
    end


    p "device_id"
    p @to_device_id
    p "device count"
    p @to_device_id.count

    sg_accident = SgAccidentHistory.where(notify: false).take

    if sg_accident.present?

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
          devices: @to_device_id
      }

      sg_accident.notify = true
      sg_accident.save
    else
      p "There is no accident or vehicle breakdown yet"
      notification_options = {
          send_date: "now",
          badge: "1",
          sound: "default",
          content:{
              fr:"There is no accident or vehicle breakdown yet",
              en:"There is no accident or vehicle breakdown yet"
          },
          data:{
              accident_datetime: Time.now,
              latitude: 0,
              longitude: 0,
              type: ""
          },
          devices: @to_device_id
      }

    end

    if @to_device_id.count > 0
      options = @auth.merge({:notifications  => [notification_options]})
      options = {:request  => options}
      full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
      url = URI.parse(full_path)
      req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
      req.body = options.to_json
      con = Net::HTTP.new(url.host, url.port)
      con.use_ssl = true
      r = con.start {|http| http.request(req)}
      p "pushwoosh"
    end



    #vehicleBreakdown = VehicleBreakdown.where(notify: false).take
    #accident = Accident.where(notify: false).take
    #weather = Weather.where(notify: false).take
    #heavyTraffic = HeavyTraffic.where(notify: false).take

  end



end
