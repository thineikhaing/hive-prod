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
      if type == "Accident" || type == "Weather" || type == "Heavy Traffic"

        if type == "Vehicle Breakdown"
          type = "VehicleBreakdown"
        elsif type == "Heavy Traffic"
          string = "HeavyTraffic"
          type = string
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

    accident = Accident.where(notify: false).take

    users_to_push = []
    @users = User.all
    time_allowance = Time.now - 10.minutes.ago
    @users.each do |u|
      if u.check_in_time.present?
        p time_difference = Time.now - u.check_in_time
        unless time_difference.to_i > time_allowance.to_i
          users_to_push.push(u)
        end
      end
    end

    if accident.present?
     # users_to_push = get_active_users_to_push(accident.latitude, accident.longitude, 50)

     to_device_id = []

     users_to_push.each do |u|
       user= User.find_by_id(u)
       if user.data.present?
         hash_array = user.data
         device_id = hash_array["device_id"] if  hash_array["device_id"].present?
         to_device_id.push(device_id)
       end
     end

     p "device_id"
     p to_device_id

     notification_options = {
         send_date: "now",
         badge: "1",
         sound: "default",
         content:{
             fr:accident.message,
             en:accident.message
         },
         data:{
           accident_datetime: accident.accident_datetime,
           latitude: accident.latitude,
           longitude: accident.longitude
         },
         devices: to_device_id
     }

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

     accident.notify = true
     accident.save


    end

    vehicleBreakdown = VehicleBreakdown.where(notify: false).take
    if vehicleBreakdown.present?
     # users_to_push = get_active_users_to_push(vehicleBreakdown.latitude, vehicleBreakdown.longitude, 50)
     to_device_id = []

     users_to_push.each do |u|
       user= User.find_by_id(u)
       if user.data.present?
         hash_array = user.data
         device_id = hash_array["device_id"] if  hash_array["device_id"].present?
         to_device_id.push(device_id)
       end
     end


     p "device_id"
     p to_device_id
     notification_options = {
         send_date: "now",
         badge: "1",
         sound: "default",
         content:{
             fr:vehicleBreakdown.message,
             en:vehicleBreakdown.message
         },
         data:{
             accident_datetime: vehicleBreakdown.accident_datetime,
             latitude: vehicleBreakdown.latitude,
             longitude: vehicleBreakdown.longitude
         },
         devices: to_device_id
     }

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

     vehicleBreakdown.notify = true
     vehicleBreakdown.save
    end

    #
    #
    #weather = Weather.where(notify: false).take
    #if weather.present?
    #  users_to_push = get_active_users_to_push(weather.latitude, weather.longitude, 50)
    #
    #  to_device_id = []
    #
    #  users_to_push.each do |u|
    #    user= User.find_by_id(u)
    #    if user.data.present?
    #      hash_array = user.data
    #      device_id = hash_array["device_id"] if  hash_array["device_id"].present?
    #      to_device_id.push(device_id)
    #    end
    #  end
    #
    #
    #  p "device_id"
    #  p to_device_id
    #
    #  notification_options = {
    #      send_date: "now",
    #      badge: "1",
    #      sound: "default",
    #      content:{
    #          fr:weather.message,
    #          en:weather.message
    #      },
    #      data:{
    #          accident_datetime: weather.accident_datetime,
    #          latitude: weather.latitude,
    #          longitude: weather.longitude
    #      },
    #      devices: to_device_id
    #  }
    #
    #  options = @auth.merge({:notifications  => [notification_options]})
    #  options = {:request  => options}
    #
    #  full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
    #  url = URI.parse(full_path)
    #  req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
    #  req.body = options.to_json
    #  con = Net::HTTP.new(url.host, url.port)
    #  con.use_ssl = true
    #
    #  r = con.start {|http| http.request(req)}
    #
    #  p "pushwoosh"
    #
    #  weather.notify = true
    #  weather.save
    #end
    #
    #heavyTraffic = HeavyTraffic.where(notify: false).take
    #if heavyTraffic.present?
    #  users_to_push = get_active_users_to_push(heavyTraffic.latitude, heavyTraffic.longitude, 50)
    #
    #  to_device_id = []
    #
    #  users_to_push.each do |u|
    #    user= User.find_by_id(u)
    #    if user.data.present?
    #      hash_array = user.data
    #      device_id = hash_array["device_id"] if  hash_array["device_id"].present?
    #      to_device_id.push(device_id)
    #    end
    #  end
    #
    #
    #  p "device_id"
    #  p to_device_id
    #
    #
    #  notification_options = {
    #      send_date: "now",
    #      badge: "1",
    #      sound: "default",
    #      content:{
    #          fr:heavyTraffic.message,
    #          en:heavyTraffic.message
    #      },
    #      data:{
    #          accident_datetime: heavyTraffic.accident_datetime,
    #          latitude: heavyTraffic.latitude,
    #          longitude: heavyTraffic.longitude
    #      },
    #      devices: to_device_id
    #  }
    #
    #  options = @auth.merge({:notifications  => [notification_options]})
    #  options = {:request  => options}
    #
    #  full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
    #  url = URI.parse(full_path)
    #  req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
    #  req.body = options.to_json
    #  con = Net::HTTP.new(url.host, url.port)
    #  con.use_ssl = true
    #
    #  r = con.start {|http| http.request(req)}
    #
    #  p "pushwoosh"
    #
    #  heavyTraffic.notify = true
    #  heavyTraffic.save
    #
    #end

  end


  def self.get_active_users_to_push(current_lat, current_lng, raydius)
    usersArray = [ ]
    activeUsersArray = []

    users = User.nearest(current_lat, current_lng, raydius)
    p users.count
    time_allowance = Time.now - 10.minutes.ago


    users.each do |u|
      usersArray.push(u)
      #if u.check_in_time.present?
      #  time_difference = Time.now - u.check_in_time
      #  unless time_difference.to_i > time_allowance.to_i
      #    usersArray.push(u)
      #  end
      #end
    end
  end

end
