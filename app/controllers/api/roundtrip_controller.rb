class Api::RoundtripController < ApplicationController
  require 'google_maps_service'

  def get_route_by_travelMode
# Setup API keys
    mode = params[:mode]
    transit_mode = params[:transit_mode]
    start_address = params[:start_address]
    end_address = params[:end_address]

    price1= 0.0
    price2= 0.0
    price3= 0.0
    gmaps = GoogleMapsService::Client.new(key: GoogleAPI::Google_Key)

    # Simple directions

    if mode == "taxi"

      mode = "driving"

    elsif mode == "bicycling"
      mode = "walking"

    end

    if params[:transit_mode]
      routes = gmaps.directions(
          start_address,
          end_address,
          transit_mode: transit_mode,
          mode: mode,
          alternatives: true)
    else

      routes = gmaps.directions(
          start_address,
          end_address,
          mode: mode,
          alternatives: true)
    end


    p "total raw number of routes"
    p routes.count

    fastest_route = Hash.new
    cheapest_route =Hash.new
    tempHash = Hash.new

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

            p price3

          end

        elsif step[:travel_mode] == "DRIVING"
          p "DRIVING"
        end

      end

      p "total estiamte price"
      totalestimateprice = price1 + price2 + price3
      p totalestimateprice = totalestimateprice.round(2)

      tempHash[:total_estimate_price] = totalestimateprice

      route.merge!(tempHash)
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

end
