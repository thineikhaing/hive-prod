class Api::RoundtripController < ApplicationController
  require 'google_maps_service'

  def get_route_by_travelMode
# Setup API keys
    mode = params[:mode]
    transit_mode = params[:transit_mode]
    start_latitude = params[:start_latitude]
    start_longitude = params[:start_longitude]
    end_latitude = params[:end_latitude]
    end_longitude = params[:end_longitude]



    price1= 0.0
    price2= 0.0
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
      routes = gmaps.directions(
          "#{start_latitude},#{start_longitude}",
          "#{end_latitude},#{end_longitude}",
          transit_mode: transit_mode,
          mode: mode,
          alternatives: true)
    else

      routes = gmaps.directions(
          "#{start_latitude},#{start_longitude}",
          "#{end_latitude},#{end_longitude}",
          mode: mode,
          alternatives: true)
    end


    p "total raw number of routes"
    p routes.count
    totalestimateprice = 0.0
    fastest_route = Hash.new
    cheapest_route =Hash.new
    tempHash = Hash.new
    tempPrice1 = Hash.new
    tempPrice2 = Hash.new
    tempPrice3 = Hash.new
    #bubble sort by distance to get the fastest route
    routes =  routes if routes.size <= 1 # already sorted

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
    p "fasted number of routes"
    p routes.count


    # @estimate_price = 0.0

    fastest_route.each do |route|
      p "+++++++++++++"
      p legs = route[:legs][0][:distance][:value]
      steps = route[:legs][0][:steps]
      p "depature_address"
      p depature_address =  route[:legs][0][:start_address]

      steps.each do |step|
        if step[:travel_mode] == "TRANSIT"
          vehicle = step[:transit_details][:line][:vehicle]
          station = step[:transit_details][:line][:short_name]
          step_distance = (step[:distance][:value]* 0.001).round(1)

          if vehicle[:type] == "SUBWAY"
            p "station"
            p station
              if station ==  "NE" || station == "CC" || station == "DT"
                p "calculate price based on NE CC DT"
                if step_distance > 40.2
                  price1 =  2.28
                else

                  CSV.foreach("db/NE-CC-DT.csv") do |row|
                    range = row[0]
                    num1= range.match(",").pre_match.to_f
                    num2= range.match(",").post_match.to_f

                    if step_distance.between?(num1,num2)
                      price1 =  (row[1].to_i* 0.01)
                      price1 =   price1.round(2)
                    end

                  end

                end

                tempPrice1[:estimate_price] = price1
                step[:distance].merge!(tempPrice1)
                p price1

              else
                p "calculate price based on NS EW BPLRT SPLRT"
                if step_distance > 40.2
                  price2 =  2.03

                else
                  CSV.foreach("db/NS-EW-LRT.csv") do |row|
                    range = row[0]
                    num1= range.match(",").pre_match.to_f
                    num2= range.match(",").post_match.to_f

                    if step_distance.between?(num1,num2)

                      price2 =  (row[1].to_i* 0.01)
                      price2=  price2.round(2)
                    end

                  end

                end
                tempPrice2[:estimate_price] = price2
                step[:distance].merge!(tempPrice2)
                p price2

              end
          else
            p "bus number"
            p station
            p "calculate price based on buses"
            if step_distance > 40.2
              price3 =  2.03
            else

              CSV.foreach("db/sms-bus.csv") do |row|
                range = row[0]
                num1= range.match(",").pre_match.to_f
                num2= range.match(",").post_match.to_f

                if step_distance.between?(num1,num2)

                  price3 =  (row[1].to_i* 0.01)
                  price3 = price3.round(2)
                end

              end

            end
            tempPrice3[:estimate_price] = price3
            step[:distance].merge!(tempPrice3)
            p price3
          end

          p "total estiamte price"
          totalestimateprice = price1 + price2 + price3
          p totalestimateprice = totalestimateprice.round(2)

        end

      end

      if mode = "driving"

        drivingHash = Hash.new

        p "DRIVING"
        p total_distance_km =  (route[:legs][0][:distance][:value]* 0.001).round(1)
        p total_duration_min =  route[:legs][0][:duration][:value] / 60
        p total_estimated_fare = calculate_taxi_rate(depature_address ,total_distance_km, total_duration_min)

        p "calculate_taxi_rate"
        p "flat down rate"
        p @flat_rate
        p "net meter fare"
        p @net_meterfare
        p "waiting charge"
        p @waiting_charge
        p "peek hour charge"
        p @peekhour_charge
        p "late hour charge"
        p @latehour_charge
        p "public holiday charge"
        p @pbHoliday_charge
        p "location charge"
        p @location_charge


        p "total estiamte price"
        p totalestimateprice = total_estimated_fare.round(2)

        drivingHash = { flate_rate: @flat_rate, net_meter_fare: @net_meterfare,
                        waiting_charge: @waiting_charge, peek_hour_charge: @peekhour_charge,
                        late_hour_charge: @latehour_charge, public_holidy_charge: @pbHoliday_charge ,
                        location_charge: @location_charge}


      end

      tempHash[:total_estimate_price] = totalestimateprice
      route.merge!(tempHash)
      route.merge!(drivingHash)
      p "+++++++++++++"

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
    changi_airport_friday_to_Sunday = 5 # (Singapore Changi Airport: Friday - Sunday from 1700 to 0000 hours)
    changi_airport = 3
    seletar_airport = 3                   # (Seletar Airport)
    sentosa = 3                           # S$3.00 (Resorts World Sentosa)
    expo = 2                              # S$2.00 (Singapore Expo)
    waiting_min = total_distance_km/2       # for 10 km waiting time is 5mins

    today = Time.new.utc.in_time_zone

    morning_t1 = Time.parse('06:00')
    morning_t2 = Time.parse('09:30')
    evening_t1 = Time.parse('18:00')
    evening_t2 = Time.parse('00:00')
    late_t1    = Time.parse('00:00')
    late_t2    = Time.parse('05:59')

    changi_t1 = Time.parse('17:00')
    changi_t2 = Time.parse('00:00')

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
      @waiting_charge = waiting_min * waiting_rate


    # calculate charge for peek hours
    if !(today.saturday? || today.sunday?)
      p "it's weekdays"
      if today.to_f > morning_t1.to_f and today.to_f < morning_t2.to_f
        p "time is between morning peekhour"
        @peekhour_charge = @net_meterfare * peekhour
      end
    end

    if  today.to_f > evening_t1.to_f and today.to_f < evening_t2.to_f
      p "time is between evening peekhour"
      @peekhour_charge = @net_meterfare * peekhour
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
        @location_charge = 5
      else
        p "not friday nor sunday"
        p @location_charge = 3
      end
    end



    p total_estimated_fare = @flat_rate + @net_meterfare + @waiting_charge +  @peekhour_charge + @latehour_charge + @pbHoliday_charge + @location_charge


    return total_estimated_fare
    end

 end

end

