class Api::RoundtripController < ApplicationController
  require 'google_maps_service'
  after_filter  :set_access_control_headers

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def get_route_by_travelMode
# Setup API keys
    mode = params[:mode]
    transit_mode = params[:transit_mode]
    start_latitude = params[:start_latitude]
    start_longitude = params[:start_longitude]
    end_latitude = params[:end_latitude]
    end_longitude = params[:end_longitude]

    start_address = params[:start_address]
    end_address = params[:end_address]
    alternative = params[:alternative]

    ncd_price = 0.0
    enl_price = 0.0
    ew_ns_lrt = 0.0
    nel_ccl_dtl = 0.0
    price3= 0.0
    gmaps = GoogleMapsService::Client.new(key: GoogleAPI::Google_Key)

    @flat_rate=0.0, @net_meterfare= 0.0,  @waiting_charge= 0.0, @peekhour_charge = 0.0 , @latehour_charge = 0.0 , @pbHoliday_charge= 0.0, @location_charge=0.0

    # Simple directions

    if mode == "taxi"

      mode = "driving"

    elsif mode == "bicycling"
      mode = "walking"

    end


    if params[:transit_mode]
      if start_address.present?
        routes = gmaps.directions(
            start_address,
            end_address,
            transit_mode: transit_mode,
            mode: mode,
            alternatives: true)
      else
        routes = gmaps.directions(
            "#{start_latitude},#{start_longitude}",
            "#{end_latitude},#{end_longitude}",
            transit_mode: transit_mode,
            mode: mode,
            alternatives: true)
      end

    else
      if start_address.present?
        routes = gmaps.directions(
            start_address,
            end_address,
            mode: mode,
            alternatives: true)
      else
        routes = gmaps.directions(
            "#{start_latitude},#{start_longitude}",
            "#{end_latitude},#{end_longitude}",
            mode: mode,
            alternatives: true)
      end

    end


    totalestimateprice = 0.0
    fastest_route = Hash.new
    cheapest_route =Hash.new
    tempHash = Hash.new
    tempPrice1 = Hash.new
    tempPrice2 = Hash.new
    tempPrice3 = Hash.new


    #bubble sort by distance to get the fastest route
    routes =  routes if routes.size <= 1 # already sorted
                                                                                  p
    loop do
      swapped = false

      0.upto(routes.size-2) do |i|

        routes[i][:legs][0][:distance][:value]
        routes[i+1][:legs][0][:distance][:value]

        if routes[i][:legs][0][:distance][:value] > routes[i+1][:legs][0][:distance][:value]
          routes[i] , routes[i+1] = routes[i+1], routes[i] # swap values
          swapped = true
        end

      end

      break unless swapped

    end
    fastest_route  = routes

    # @estimate_price = 0.0

    total_walking_distance = 0.0

    fastest_route.each_with_index do |route, r_index|
      p "+++++++++++++"
      legs = route[:legs][0][:distance][:value]
      steps = route[:legs][0][:steps]
      #depature_address
      depature_address =  route[:legs][0][:start_address]
      p "steps"
      p steps.count
      if steps.count >  1

      ncd_price = 0.0
      enl_price = 0.0
      ew_ns_lrt = 0.0
      nel_ccl_dtl = 0.0
      bus_distance = 0.0
      fare = 0.0

      steps.each_with_index do |step,s_index|
        if step[:travel_mode] == "TRANSIT"
          vehicle = step[:transit_details][:line][:vehicle]
          station = step[:transit_details][:line][:name]
          step_distance = (step[:distance][:value]* 0.001).round(1)
          if vehicle[:type] == "SUBWAY"
            if station ==  "North East Line" || station == "Circle Line" || station == "Downtown Line"
              p "NE | CC | DTL "
              p nel_ccl_dtl = nel_ccl_dtl + step[:distance][:value]
            else
              p "EW | NS | LRT "
              p ew_ns_lrt = ew_ns_lrt + step[:distance][:value]
            end
          else
            p "Bus"
            p bus_distance = step[:distance][:value]
          end



        elsif step[:travel_mode] == "DRIVING"

          drivingHash = Hash.new

          total_distance_km =  (route[:legs][0][:distance][:value]* 0.001).round(1)
          total_duration_min =  route[:legs][0][:duration][:value] / 60
          total_estimated_fare = calculate_taxi_rate(depature_address ,total_distance_km, total_duration_min)

          totalestimateprice = total_estimated_fare.round(2)
          today = Time.new.utc.in_time_zone

          drivingHash = { servertime: today,flate_rate: @flat_rate, net_meter_fare: @net_meterfare,
                          waiting_charge: @waiting_charge, peek_hour_charge: @peekhour_charge,
                          late_hour_charge: @latehour_charge, public_holidy_charge: @pbHoliday_charge ,
                          location_charge: @location_charge}
          tempHash[:total_estimate_price] = totalestimateprice

          route.merge!(tempHash)
          route.merge!(drivingHash)

        elsif step[:travel_mode] == "WALKING"

          step_distance = (step[:distance][:value]* 0.001).round(1)
          total_walking_distance = total_walking_distance + step_distance

          total_frist_walking_and_transit = 0.0

          if s_index == 0
            puts "current index...#{r_index},#{s_index}"

            p "first walking distance"
            # p "check walking and  transit mode"
            first_walking = steps[s_index]
            p first_distance = (steps[s_index][:distance][:value]* 0.001).round(1)

            # p "second transit"
            second_transit = steps[s_index+1]
            # second_distance = (steps[s_index+1][:distance][:value]* 0.001).round(1)

            start_location_lat = steps[s_index+1][:start_location][:lat]
            start_location_lng = steps[s_index+1][:start_location][:lng]
            end_location_lat = steps[s_index+1][:end_location][:lat]
            end_location_lng = steps[s_index+1][:end_location][:lng]

            p "second walking distance"
            second_route = gmaps.directions(
                "#{start_location_lat},#{start_location_lng}",
                "#{end_location_lat},#{end_location_lng}",
                mode: "walking",
                alternatives: false)

            p second_distance = (second_route.first[:legs][0][:distance][:value]* 0.001).round(1)


            sub_route = Hash.new

            if start_address.present?
              walking_route = gmaps.directions(
                  start_address,
                  "#{end_location_lat},#{end_location_lng}",
                  mode: "walking",
                  alternatives: false)

              transit_route = gmaps.directions(
                  "#{end_location_lat},#{end_location_lng}",
                  end_address,
                  mode: mode,
                  alternatives: false)

            else
              walking_route = gmaps.directions(
                  "#{start_latitude},#{start_longitude}",
                  "#{end_location_lat},#{end_location_lng}",
                  mode: "walking",
                  alternatives: false)

              transit_route = gmaps.directions(
                  "#{end_location_lat},#{end_location_lng}",
                  "#{end_latitude},#{end_longitude}",
                  mode: mode,
                  alternatives: false)
            end

            transit_route

            p "walking_route"


            p "total_frist_walking_and_transit"
            p total_frist_walking_and_transit = first_distance + second_distance

            tempHash = Hash.new
            if total_frist_walking_and_transit <= 2
              p "calculate route for green options"
              p walking_route = walking_route.first
              p transit_route = transit_route.first
              tempHash[:have_green_option] = "yes"
              sub_route[:sub_walking_route] = walking_route

              sub_route[:sub_transit_route] = transit_route
            else
              tempHash[:have_green_option] = "no"

            end
            route.merge!(tempHash)
            route.merge!(sub_route)
          end

        end

      end

      end


      fare = calculate_transit_fare(ew_ns_lrt,nel_ccl_dtl,bus_distance)

      tempHash[:total_estimate_price] = fare
      route.merge!(tempHash)

    end



    cheapest_route =  routes if routes.size <= 1 # already sorted

    loop do
      swapped = false

      0.upto(fastest_route.size-2) do |i|

        fastest_route[i][:total_estimate_price]
        fastest_route[i+1][:total_estimate_price]

        if fastest_route[i][:total_estimate_price] > fastest_route[i+1][:total_estimate_price]
          fastest_route[i] , fastest_route[i+1] = fastest_route[i+1], fastest_route[i] # swap values
          swapped = true
        end

      end

      break unless swapped

    end
    cheapest_route  = fastest_route
    p "cheapest_route"
    cheapest_route.each do |route|
      p route[:total_estimate_price]
    end

    render json: {fastest_routes: fastest_route,cheapest_routes: cheapest_route}

  end

  def calculate_transit_fare(smrt, sbs, bus)

    total_distance = (smrt + sbs + bus) * 0.001
    compare_distance = []
    p 'compare_distance'
    p compare_distance.push(smrt,sbs,bus)
    max_distance = compare_distance.max

    p "look up price table"
    if max_distance == smrt
      p "SMRT"
      price_table = "db/NS-EW-LRT.csv"
      total_fare = 2.03 if total_distance >= 40.2
    elsif max_distance == sbs
      p "SBS"
      price_table = "db/NE-CC-DT.csv"
      total_fare = 2.28 if total_distance >= 40.2
    else
      p "BUS"
      total_fare = 2.03 if total_distance >= 40.2
      price_table = "db/sms-bus.csv"
    end


    if total_distance > 0
      CSV.foreach(price_table) do |row|
        range = row[0]
        num1= range.match(",").pre_match.to_f
        num2= range.match(",").post_match.to_f

        if total_distance.between?(num1,num2)
          total_fare =  (row[1].to_i* 0.01)
        end
      end
    end

    total_fare.round(2)

  end

  def calculate_taxi_rate(depature_address ,total_distance_km, total_duration_min)
    p "DEPATURE"
    p depature= depature_address.downcase!
    depature= depature.to_s
    distance = total_distance_km - 1
    total_time = total_duration_min

    @flat_rate = 3.2
    firstmeter =  0.55                # (0.22 for every 400 m | 0.55 per km thereafter or less > 1 km and ≤ 10 km)
    secondmeter = 0.63                # (0.22 for every 350 m | 0.63 per km thereafter or less > 10 km)
    waiting_rate = 0.30               # (0.22 every 45 seconds or less | 0.30 per min)
    peekhour = 0.25                   # 25% of metered fare (Monday to Friday 0600 - 0930 and 1800 – 0000 hours)
    public_holiday = 0.25             # 25% of metered fare
    late_night = 0.5                  # 50% of metered fare (0000 – 0559 hours)

    # location
    changi_airport_friday_to_Sunday = 5   # (Singapore Changi Airport: Friday - Sunday from 1700 to 0000 hours)
    changi_airport = 3
    seletar_airport = 3                   # (Seletar Airport)
    sentosa = 3                           # S$3.00 (Resorts World Sentosa)
    expo = 2                              # S$2.00 (Singapore Expo)
    waiting_min = total_distance_km/2       # for 10 km waiting time is 5mins

    p today = Time.new.utc.in_time_zone

    morning_t1 = Time.zone.parse('06:00')
    morning_t2 = Time.zone.parse('09:30')
    evening_t1 = Time.zone.parse('18:00')
    evening_t2 = Time.zone.parse('00:00')
    late_t1    = Time.zone.parse('00:00')
    late_t2    = Time.zone.parse('05:59')

    changi_t1 = Time.zone.parse('17:00')
    changi_t2 = Time.zone.parse('00:00')

    first_10km = 0.0,rest_km =0.0

     @net_meterfare= 0.0,  @waiting_charge= 0.0, @peekhour_charge = 0.0 , @latehour_charge = 0.0 , @pbHoliday_charge= 0.0, @location_charge=0.0

    if (distance - 10) != 0 || distance < 10
      p "first 10 km"
      p first_10km = 10 * firstmeter
    if distance > 10
      p "rest meter"
      restmeter = distance - 10
      p rest_km = restmeter * secondmeter
    end

    # sum of the first 10 km and rest km for net meter fare
    p "net meter fare"
    p @net_meterfare = (first_10km + rest_km).round(2)

    # calculate charge for waiting time in traffic
      @waiting_charge = (waiting_min * waiting_rate).round(2)


    # calculate charge for peek hours
    if !(today.saturday? || today.sunday?)
      p "it's weekdays"
      if today.to_f > morning_t1.to_f and today.to_f < morning_t2.to_f
        p "time is between morning peekhour"
        p @peekhour_charge = @net_meterfare * peekhour
      end
    end

    if  today.to_f > evening_t1.to_f and today.to_f < evening_t2.to_f
      p "time is between evening peekhour"
      p @peekhour_charge = @net_meterfare * peekhour
    end


    # calculate charge for late night

    if  today.to_f > late_t1.to_f and today.to_f < late_t2.to_f
      p "time is between evening peekhour"
      @latehour_charge = @net_meterfare * late_night
    end


    # calculate charge for holidays
    publicH = Holidays.on(today, :sg)

    if publicH.count == 1
      pbHoliday_charge = @net_meterfare * public_holiday
    end

    # calculate charge based on location
    if depature.include?('seletar') ||  depature.include?('sentosa') ||  depature.include?('resorts world')
      @location_charge = 3
    end

    if depature_address.include?('expo')
      @location_charge = 2
    end

    if depature.include?('changi') ||  depature.include?('terminal') ||  depature.include?('airport')

      if today.friday? || today.saturday? || today.sunday?
        p "today is friday to sunday"
        if  today.to_f > changi_t1.to_f and today.to_f < changi_t2.to_f
          @location_charge = 5
        else
          @location_charge = 3
        end

      else
        p "not friday nor sunday"
        p @location_charge = 3
      end
    end

    p total_estimated_fare = @flat_rate + @net_meterfare + @waiting_charge +  @peekhour_charge + @latehour_charge + @pbHoliday_charge + @location_charge


    return total_estimated_fare
    end

  end

  def broadcast_trainfault
    name = params[:name]
    station1 = params[:station1]
    station2 = params[:station2]
    towards = params[:towards]
    reason = params[:reason]

    if Rails.env.production?
      appID = PushWoosh_Const::RT_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::RT_S_APP_ID
    else
      appID = PushWoosh_Const::RT_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    hive_application = HiveApplication.find_by_api_key(params[:app_key])
    users = User.where("app_data ->'app_id#{hive_application.id}' = '#{hive_application.api_key}'")

    to_device_id = []
    time_allowance = Time.now - 10.minutes.ago
    users.each do |u|
      if u.check_in_time.present?
        time_difference = Time.now - u.check_in_time
        unless time_difference.to_i > time_allowance.to_i
          hash_array = u.data
          device_id = hash_array["device_id"] if  hash_array["device_id"].present?
          to_device_id.push(device_id)
        end
      end
    end

    devicecount = to_device_id.count rescue '0'

    message = ""
    if station1.present? && station2.present?
      message = "[#{name}]"+reason +", between "+station1+" and "+station2

    elsif station1.present? && station2.blank?
      message =  "[#{name}]"+reason +" from "+station1
    end

    if towards.present?
      message += " towards "+towards
    end

    notification_options = {
        send_date: "now",
        badge: "1",
        sound: "default",
        content:{
            fr:message,
            en:message
        },
        data:{
            trainfault_datetime: Time.now,
            smrtline: name,
            station1: station1,
            station2: station2,
            towards: towards,
            type: "train fault"
        },
        devices: to_device_id
    }

    if to_device_id.count > 0
      Pushwoosh::PushNotification.new(@auth).notify_devices(message, to_device_id, notification_options)
    end

    sns = Aws::SNS::Client.new
    target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti'

    iphone_notification = {
        aps: {
            alert: message,
            sound: "default",
            badge: 0,
            extra:  {
                trainfault_datetime: Time.now,
                smrtline: name,
                station1: station1,
                station2: station2,
                towards: towards,
                type: "train fault"
            }
        }
    }

    android_notification = {
        data: {
            message: message,
            badge: 0,
            extra:  {
                        trainfault_datetime: Time.now,
                        smrtline: name,
                        station1: station1,
                        station2: station2,
                        towards: towards,
                        type: "train fault"
                    }
        }
    }

    sns_message = {
        default: message,
        APNS_SANDBOX: iphone_notification.to_json,
        APNS: iphone_notification.to_json,
        GCM: android_notification.to_json
    }.to_json


    sns.publish(target_arn: target_topic, message: sns_message, message_structure:"json")

    render json:  {message: message, device_count: devicecount}


  end

  def get_nearby_taxi

    latitude = params[:latitude]
    longitude = params[:longitude]
    radius = params[:radius]

    radius = 1 if radius.nil?
    center_point = [latitude.to_f, longitude.to_f]
    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
    places = TaxiAvailability.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3]).limit(10)


    gmaps = GoogleMapsService::Client.new(key: GoogleAPI::Google_Key)


    duration = "0 min"
    taxi_list = []
    places.each do |place|


      routes = gmaps.directions(
          "#{latitude},#{longitude}",
          "#{place.latitude},#{place.longitude}",
          transit_mode: "driving",
          alternatives: false)

      routes.each_with_index do |route|
        duration = route[:legs][0][:duration][:text]
      end

      taxi_list.push([place.latitude,place.longitude, duration])
    end

    render json:  {taxi_list: taxi_list, taxi_count: taxi_list.count}
  end

  def broadcast_roundtrip_users
    hiveapplication = HiveApplication.find_by_api_key(params[:app_key])

    # place = Place.new
    # place = place.add_record("", current_user.last_known_latitude, current_user.last_known_longitude, "", 0,nil, nil, current_user.id, current_user.authentication_token,"","","","","","")

    p "Push Woosh Authentication"
    if Rails.env.production?
      appID = PushWoosh_Const::RT_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::RT_S_APP_ID
    else
      appID = PushWoosh_Const::RT_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    user_id = []
    to_device_id = []
    to_endpoint_arn = []
    users = User.where("app_data ->'app_id#{hiveapplication.id}' = '#{hiveapplication.api_key}'")

    time_allowance = Time.now - 10.minutes.ago
    users.each do |u|
      if u.check_in_time.present?
        time_difference = Time.now - u.check_in_time
        unless time_difference.to_i > time_allowance.to_i
          if u.data.present? && u.id != current_user.id
            hash_array = u.data
            device_id = hash_array["device_id"] if  hash_array["device_id"].present?
            endpoint_arn = hash_array["endpoint_arn"] if  hash_array["endpoint_arn"].present?
            to_device_id.push(device_id)
            to_endpoint_arn.push(endpoint_arn)
            user_id.push(u.id)
          end
        end
      end
    end

    params[:start_name].present? ? start_name = params[:start_name] : start_name = nil
    params[:start_address].present? ? start_address = params[:start_address] : start_address = ""
    params[:start_latitude].present? ? start_latitude = params[:start_latitude] : start_latitude = nil
    params[:start_longitude].present? ? start_longitude = params[:start_longitude] : start_longitude = nil
    params[:start_place_id].present? ? start_place_id = params[:start_place_id] : start_place_id = nil
    params[:start_source].present? ? start_source = params[:start_source] : start_source = ""
    params[:start_source_id].present? ? start_source_id = params[:start_source_id] : start_source_id = nil

    params[:end_name].present? ? end_name = params[:end_name] : end_name = nil
    params[:end_address].present? ? end_address = params[:end_address] : end_address = ""
    params[:end_latitude].present? ? end_latitude = params[:end_latitude] : end_latitude = nil
    params[:end_longitude].present? ? end_longitude = params[:end_longitude] : end_longitude = nil
    params[:end_place_id].present? ? end_place_id = params[:end_place_id] : end_place_id = nil
    params[:end_source].present? ? end_source = params[:end_source] : end_source = ""
    params[:end_source_id].present? ? end_source_id = params[:end_source_id] : end_source_id = nil

    category = ""
    locality=""
    country=""
    postcode=""
    img_url = nil
    choice="others"
    start_id = 0
    end_id = 0

    if params[:start_place_id] || params[:start_longitude]  || params[:start_longitude]  || params[:start_source_id]
      place = Place.new
      start_place = place.add_record(start_name, start_latitude, start_longitude, start_address, start_source, start_source_id, start_place_id, current_user.id, current_user.authentication_token, choice,img_url,category,locality,country,postcode)
      p "start place info::::"
      p start_id = start_place[:place].id
      p start_place[:place].name

      end_place = place.add_record(end_name, end_latitude, end_longitude, end_address, end_source, end_source_id, end_place_id, current_user.id, current_user.authentication_token, choice,img_url,category,locality,country,postcode)
      p "end place info::::"
      p end_id = end_place[:place].id
      p end_place[:place].name

    end

    user_place = Place.create_place_by_lat_lng(current_user.last_known_latitude, current_user.last_known_longitude,current_user)

    if user_place.nil?
      user_place = Place.first
    end

    message = params[:message]

    topic = Topic.create(title:message, user_id: current_user.id, topic_type: 0, hiveapplication_id: hiveapplication.id,
                         place_id: user_place.id, start_place_id: start_id, end_place_id: end_id)
    topic.hive_broadcast
    topic.app_broadcast

    p topic.title

    # notification_options = {
    #     send_date: "now",
    #     badge: "1",
    #     sound: "default",
    #     content:{
    #         fr:message,
    #         en:message
    #     },
    #     data:{
    #         topic: topic,
    #         message: topic.title,
    #         broadcast_user: current_user.id,
    #         shared: true
    #     },
    #     devices: to_device_id
    # }
    #
    # if to_device_id.count > 0
    #   Pushwoosh::PushNotification.new(@auth).notify_devices(message, to_device_id, notification_options)
    # end

    to_endpoint_arn.each do |arn|

      if arn.present?

        user_arn = arn

        sns = Aws::SNS::Client.new
        # target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti'

        iphone_notification = {
            aps: {
                alert: topic.title,
                sound: "default",
                badge: 0,
                extra:  {
                    topic_id: topic.id,
                    topic_title: topic.title,
                    broadcast_user: current_user.id,
                    shared: true
                }
            }
        }

        android_notification = {
            data: {
                message: topic.title,
                badge: 0,
                topic_id: topic.id,
                topic_title: topic.title,
                broadcast_user: current_user.id,
                shared: true
            }
        }

        sns_message = {
            default: topic.title,
            APNS_SANDBOX: iphone_notification.to_json,
            APNS: iphone_notification.to_json,
            GCM: android_notification.to_json
        }.to_json


        sns.publish(target_arn: user_arn, message: sns_message, message_structure:"json")

      end
    end



    render json:{status: 200, topic:topic, message: "broadcast topic create sucessfully!"}

  end

  def get_rt_privacy_policy
    hiveapp = HiveApplication.find_by_api_key(params[:app_key])
    pp = PrivacyPolicy.find_by_hiveapplication_id(hiveapp.id)
    title = pp.title rescue ''
    content = pp.content rescue ''
    render json:{title: title,content: content}
  end

  def get_bus_arrival_time
    tempnextBus1 = Hash.new
    tempnextBus2 = Hash.new
    tempnextBus3 = Hash.new
    bus_info = nil
    stop_name = params[:stop_name]
    service_no = params[:service_no]
    latitude = params[:latitude]
    longitude = params[:longitude]

    if latitude.present? && longitude.present? && stop_name.present? && service_no.present?
      name_count = 0
      center_point = [latitude.to_f, longitude.to_f]
      box = Geocoder::Calculations.bounding_box(center_point, 0.05, {units: :km})
      p bus_info = SgBusStop.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])

      if bus_info.count > 1
        bus_info.each do |info|
          if info.description == stop_name
            name_count +=1
          end
        end

        if name_count == 1
          bus_info  = SgBusStop.where(description: stop_name).take
        else
          bus_info = bus_info.take
        end

      else
        bus_info = bus_info.take
      end

        p "bus info"


       p bus_info
      if bus_info.present?
        p "bus id"
        p bus_info.bus_id

        uri = URI('http://datamall2.mytransport.sg/ltaodataservice/BusArrival')
        params = { :BusStopID => bus_info.bus_id, :ServiceNo => service_no, :SST => true}
        uri.query = URI.encode_www_form(params)
        res = Net::HTTP::Get.new(uri,
                                 initheader = {"accept" =>"application/json",
                                               "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==",
                                               "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
        con = Net::HTTP.new(uri.host, uri.port)
        r = con.start {|http| http.request(res)}
        results = JSON.parse(r.body)
        p results = results["Services"]
      end

      if results.present?

        nextBus1 = results[0]["NextBus"]
        status = results[0]["Status"]

        if status == "In Operation" and nextBus1["EstimatedArrival"] != ""
          nextbus_arrivalTime1 = Time.parse(nextBus1["EstimatedArrival"]).strftime("at %I:%M%p")
          tempnextBus1[:nextBusInText] = nextbus_arrivalTime1
          results[0]["NextBus"].merge!(tempnextBus1)

          nextBus2 = results[0]["SubsequentBus"]
          if nextBus2["EstimatedArrival"].present? and nextBus2["EstimatedArrival"] != ""
            nextbus_arrivalTime2 = Time.parse(nextBus2["EstimatedArrival"]).strftime("at %I:%M%p")
            tempnextBus2[:nextBusInText] = nextbus_arrivalTime2
          else
            tempnextBus2[:nextBusInText] = ""
          end
          results[0]["SubsequentBus"].merge!(tempnextBus2)

          nextBus3 = results[0]["SubsequentBus3"]
          if nextBus3["EstimatedArrival"].present? and nextBus3["EstimatedArrival"] != ""
            nextbus_arrivalTime3 = Time.parse(nextBus3["EstimatedArrival"]).strftime("at %I:%M%p")
            tempnextBus3[:nextBusInText] = nextbus_arrivalTime3
          else
            tempnextBus3[:nextBusInText] = ""
          end
          results[0]["SubsequentBus3"].merge!(tempnextBus3)
        end

        # results[0].delete("SubsequentBus3")

        render json:{results: results}
      else
        render json:{error_msg:"No Available Result!"}

      end

    else
      render json:{error_msg:"Parameter latitude, longitude, stop_name and service_no must be presented."}
    end

  end

  require "base64"
  def upload_rt_placeImage

    uploader = PhotoUploader.new
    uploader.retrieve_from_store!(params[:image_data])
    uploader.cache_stored_file!
    uploader.resize_to_fit(uploader.get_geometry[0]/5,uploader.get_geometry[1]/5)
    uploader.store!

    # aws_access_key_id='AKIAIJMZ5RLXRO6LJHPQ',     # required
    # aws_secret_access_key='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',    # required
    #
    # s3 = AWS::S3.new(access_key_id: aws_access_key_id,secret_access_key: aws_secret_access_key)
    # bucket = s3.buckets['hivestagingimages']
    # data = Base64.decode64(params[:image_data].to_s)
    # type = params[:contentType].to_s
    # name = params[:image_name]
    # obj = bucket.objects.create(name,data,{content_type:type,acl:"public_read"})
    # url = obj.public_url().to_s
    #
    render json:{status:"ok"}

  end

  def save_trip

    route_hash = Hash.new []
    user_id = params[:user_id]
    auth_token = params[:auth_token]
    start_latlng = params[:start_latlng]
    end_latlng = params[:end_latlng]

    s_lat = start_latlng.partition(',').first
    s_lng = start_latlng.partition(',').last
    e_lat = end_latlng.partition(',').first
    e_lng = end_latlng.partition(',').last

    arrival_name = params[:arrival_name]
    depature_name = params[:depature_name]
    source=  params[:source]
    transit_mode = params[:transit_mode]
    depature_time = params[:depature_time].to_datetime
    arrival_time = params[:arrival_time].to_datetime
    fare = params[:fare]
    trip_route = params[:trip_route]
    trip_eta = params[:trip_eta]

    category = ""
    locality=""
    country=""
    postcode=""
    img_url = nil
    choice="others"
    address = ""

    start_id = 0
    end_id = 0
    total_distance = 0.0

 #    ActiveRecord::Base.connection.execute("TRUNCATE TABLE trips
 # RESTART IDENTITY")

    if params[:start_latlng]
      p "start address"
      p s_geo_localization = "#{s_lat},#{s_lng}"
      s_query = Geocoder.search(s_geo_localization).first
      p address = s_query.address
      country = s_query.country
      s_query.place_id

      s_place = Place.new
      start_place = s_place.add_record(depature_name, s_lat, s_lng, address, source,
                                       "", nil, user_id, auth_token,
                                       choice,img_url,category,locality,country,postcode)
      p "start place info::::"
      p start_id = start_place[:place].id
    end

    if params[:end_latlng]
      p "end address"
      p e_geo_localization = "#{e_lat},#{e_lng}"
      e_query = Geocoder.search(e_geo_localization).first
      p address = e_query.address
      country = e_query.country
      e_query.place_id

      e_place = Place.new
      end_place = e_place.add_record(arrival_name, e_lat, e_lng, address, source,
                                     "", nil, user_id, auth_token,
                                     choice,img_url,category,locality,country,postcode)
      p "end end info::::"
      p end_id = end_place[:place].id

    end

    prev_trip = Trip.where(user_id: user_id, start_place_id: start_id, end_place_id:end_id, transit_mode: transit_mode)

    if prev_trip.present?
      user_trips  = Trip.where(user_id: user_id)
      render json:{status:"Trip is already exit.", trips: user_trips}
    else



      if source.to_i == Place::ONEMAP
        trip_route = params[:trip_route][:legs]
        trip_route.each do |index,data|
          f_detail =  Hash.new []
          t_detail =  Hash.new []
          distance = data[:distance].to_f
          total_distance = total_distance + distance
          mode = data[:mode]

          from_detail = data[:from]
          from_name = from_detail[:name]
          from_lat = from_detail[:lat]
          from_lng = from_detail[:lon]

          to_detail = data[:to]
          to_name = to_detail[:name]
          to_lat = to_detail[:lat]
          to_lng = to_detail[:lon]

          f_detail.merge!(name: from_name, lat: from_lat, lng: from_lng)
          t_detail.merge!(name: to_name, lat: to_lat, lng: to_lng)

          geo_points = data[:legGeometry][:points]
          short_name = ""
          total_stops = 0

          if data[:mode] != "WALK"
            total_stops = to_detail[:stopSequence].to_i - from_detail[:stopSequence].to_i
            short_name = data[:routeShortName]
            from_stopSequence = from_detail[:stopSequence]
            to_stopSequence = to_detail[:stopSequence]
            f_detail.merge!(stopSequence: from_stopSequence)
            t_detail.merge!(stopSequence: to_stopSequence)
          end

          route_hash[index] = {from:f_detail, to: t_detail,
                               distance:distance, mode: mode,
                               geo_point: geo_points,short_name: short_name,
                               total_stops: total_stops}

        end

        tripData = Hash.new
        tripData[:route_detail] = route_hash
        tripData[:source] = source
        tripData[:country] = country
        tripData[:trip_eta] = trip_eta
        total_distance = total_distance.round(2)

        # a.gsub!(/\"/, '\'')
        #eval(a)
        trip = Trip.create(user_id: user_id,start_place_id: start_id,
                           end_place_id: end_id,transit_mode: transit_mode,
                           depature_time: depature_time, arrival_time: arrival_time,
                           distance: total_distance, fare: fare, data: tripData,
                           depart_latlng:start_latlng, arr_latlng: end_latlng,
                           depature_name:depature_name,arrival_name:arrival_name)
        trip = trip.save!

        user_trips  = Trip.where(user_id: user_id)
        render json:{status:"save user trip!", trips: user_trips}

      else
        user_trips  = Trip.where(user_id: user_id)
        render json:{status:"saving google trip working in progess ...", trips: user_trips}
      end



    end




  end

  def get_trip
    trips  = Trip.where(user_id: params[:user_id])
    render json:{status:"ok",trips:trips}
  end

  def delete_trip
    if current_user.present?
      if params[:id].present?
        trip_to_delete = Trip.find(params[:id])
        if trip_to_delete.present?
          trip_to_delete.destroy
          trips = Trip.where(user_id: params[:user_id])

          trip_detail =  []
          trips.each do |trip|
            detail = trip.data["route_detail"]
            trip_detail.push(eval(detail))
          end

          render json: {message: "Delete trip by id.", trips: trips,trip_detail:trip_detail}  , status: 200
        end
      elsif params[:ids].present?
        p "selected id to delete"
        p selected_ids = params[:ids].to_a

        for i in 0..selected_ids.count-1
          trip_id = selected_ids[i].to_i
          Trip.find(trip_id).destroy
        end
        trips = Trip.where(user_id: params[:user_id])
        trip_detail =  []
        trips.each do |trip|
          detail = trip.data["route_detail"]
          trip_detail.push(eval(detail))
        end

        render json: {message: "Delete trip by id.", trips: trips,trip_detail:trip_detail}  , status: 200
      end
    else
      render json:{error_msg: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

end

