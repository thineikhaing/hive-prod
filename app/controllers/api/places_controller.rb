class Api::PlacesController < ApplicationController

  def create
    if current_user.present?
      params[:name].present? ? name = params[:name] : name = nil
      params[:category].present? ? category = params[:category] : category = ""
      params[:address].present? ? address = params[:address] : address = ""
      params[:latitude].present? ? latitude = params[:latitude] : latitude = nil
      params[:longitude].present? ? longitude = params[:longitude] : longitude = nil
      params[:locality].present? ? locality = params[:locality] : locality=""
      params[:place_id].present? ? place_id = params[:place_id] : place_id = nil
      params[:country].present? ? country = params[:country] : country=""
      params[:postcode].present? ? postcode = params[:postcode] : postcode=""
      params[:img_url].present? ? img_url = params[:img_url] : img_url = nil
      params[:source].present? ? source = params[:source] : source = ""
      params[:source_id].present? ? source_id = params[:source_id] : source_id = nil
      params[:app_key].present? ? app_key = params[:app_key] : app_key=nil

      #params[:region].present? ? region = params[:region] : region=nil
      #params[:website_url].present? ? website_url= params[:website_url] : website_url = nil
      params[:neighbourhood].present? ? neighbourhood = params[:neighbourhood] : neighbourhood=""
      params[:chain_name].present? ? chain_name = params[:chain_name] : chain_name = ""
      params[:contact_number].present? ? contact_number= params[:contact_number] : contact_number = ""

      choice="others"
      if app_key.present?
        mealbox_key = ""
        if Rails.env.development?
          mealbox_key = Mealbox_key::Development_Key
        elsif Rails.env.staging?
          mealbox_key = Mealbox_key::Staging_Key
        else
          mealbox_key = Mealbox_key::Production_Key
        end
        choice = "luncheon" if app_key ==  mealbox_key
      end

      place = Place.new
      place = place.add_record(name, latitude, longitude, address, source, source_id, place_id, current_user.id, current_user.authentication_token, choice,img_url,category,locality,country,postcode)
      #Checkinplace.create(place_id: places.id, user_id: current_user.id) if places.present?
      render json: place
    elsif params[:place_id] || params[:source]  || params[:source_id]
      place = Place.new

      params[:name].present? ? name = params[:name] : name = nil
      params[:latitude].present? ? latitude = params[:latitude] : latitude = nil
      params[:longitude].present? ? longitude = params[:longitude] : longitude = nil
      params[:address].present? ? address = params[:address] : address = nil
      params[:source].present? ? source = params[:source] : source = nil
      params[:source_id].present? ? source_id = params[:source_id] : source_id = nil
      params[:place_id].present? ? place_id = params[:place_id] : place_id = nil
      params[:choice].present? ? choice = params[:choice] : choice = nil
      params[:img_url].present? ? img_url = params[:img_url] : img_url = nil
      params[:place_type].present? ? place_type = params[:place_type] : place_type = nil
      params[:locality].present? ? locality = params[:locality] : locality=""
      params[:country].present? ? country = params[:country] : country=""
      params[:postcode].present? ? postcode = params[:postcode] : postcode=""

      currentuser = User.find_by_authentication_token(params[:auth_token])
      place = place.add_record(name, latitude, longitude, address, source, source_id, place_id, currentuser.id, params[:auth_token], choice,img_url,place_type,locality,country,postcode )

      render json: place


    else
      render json: { error_msg: "Params user id and/ or authentication token must be presented" } , status: 400
    end
  end

  def get_nearby_shops
    factual_data_array = []
    factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    query = factual.table("places").filters("category_ids" => {"$includes_any" => [312, 347]}).geo("$circle" => {"$center" => [params[:latitude], params[:longitude]], "$meters" => 5.to_f*1000})

    query.each do |q|
      data = { name: q["name"], latitude: q["latitude"], longitude: q["longitude"], address: q["address"], source: 3, user_id: nil, username: nil, source_id: q["factual_id"] }
      factual_data_array.push(data)
    end
    render json: { places: factual_data_array}

  end

  def retrieve_places
    data_array = [ ]
    factual_data_array = [ ]

    if params[:latitude].present? and params[:longitude].present? and params[:radius].present?
      places = Place.nearest(params[:latitude], params[:longitude], params[:radius])

      places.each do |pl|
        data_array.push(pl)
      end

      factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
      query = factual.table("global").geo("$circle" => {"$center" => [params[:latitude], params[:longitude]], "$meters" => params[:radius].to_f*1000})

      query.each do |q|
        data = { name: q["name"], latitude: q["latitude"], longitude: q["longitude"], address: q["address"], source: 3, user_id: nil, username: nil, source_id: q["factual_id"] }
        factual_data_array.push(data)
      end

      data_array.each do |da|
        factual_data_array.each do |fda|
          factual_data_array.delete(fda) if da[:name] == fda[:name]
        end
      end

      data_array = data_array + factual_data_array

      render json: { places: data_array}
    else
      render json: { error_msg: "Params latitude, longitude and radius must be presented" }, status: 400
    end
  end

  def user_recent_places
    if current_user.present?
      places_array = current_user.checkinplaces.order("created_at DESC")
      data_array = [ ]
      list_array = [ ]
      places_id_array = [ ]

      places_array.each do |pa|
        places_id_array.push(pa.place_id)
      end

      Place.where(id: [places_id_array]).each do |place|
        list_array.push(place.id) unless list_array.include?(place.id)
      end

      list_array.each_with_index do |la, i|
        break if i == 10
        place = Place.find(la)
        result = current_user.checkinplaces.where(place_id: place.id).last
        data = { name: place.name, id: place.id, latitude: place.latitude, longitude: place.longitude, created_at: result.created_at }
        data_array.push(data)
      end
      render json: data_array
    else
      render json: {error_msg: "Params user id and authentication token must be presented"},status: 400
    end
  end

  def select_venue
    # TODO: When fetching back queries, check whether it exists before processing it.
    data_array = [ ]
    factual_data_array = [ ]
    places_array = [ ]

    if params[:latitude].present? and params[:longitude].present? and params[:app_key].present?
      hiveapplication = HiveApplication.find_by(:api_key => params[:app_key])
      place = Place.nearest(params[:latitude], params[:longitude], params[:radius])
      if hiveapplication.present?

        place.each do |pl|
          if params[:auth_token].present?
            if pl.source == 6
              places_array.push(pl) if pl.user_id == current_user.id
            else
              places_array.push(pl)
            end
          else
            places_array.push(pl) unless pl.source == 6
          end
        end

        places_array.each do |pl|
          username = User.find(pl.user_id).username if pl.user_id.present?

          numOfCheckIns = Checkinplace.where(:place_id=>pl.id)

          #filter by category is only valid for factual
          if hiveapplication.app_type.include? "Food"
            if pl.category.include? "Food"
              if pl.user_id.present?
                data = { id: pl.id, name: pl.name, latitude: pl.latitude, longitude: pl.longitude, address: pl.address, source: pl.source, user_id: pl.user_id, username: username, users_check_in: numOfCheckIns.count(:user_id, distinct: true), img_url: pl.img_url }
                data_array.push(data)
              else
                data = { id: pl.id, name: pl.name, latitude: pl.latitude, longitude: pl.longitude, address: pl.address, source: pl.source, user_id: nil, username: nil, users_check_in: numOfCheckIns.count(:user_id, distinct: true), img_url: pl.img_url }
                data_array.push(data)
              end
            end
          else
            if pl.user_id.present?
              data = { id: pl.id, name: pl.name, latitude: pl.latitude, longitude: pl.longitude, address: pl.address, source: pl.source, user_id: pl.user_id, username: username, users_check_in: numOfCheckIns.count(:user_id, distinct: true), img_url: pl.img_url }
              data_array.push(data)
            else
              data = { id: pl.id, name: pl.name, latitude: pl.latitude, longitude: pl.longitude, address: pl.address, source: pl.source, user_id: nil, username: nil, users_check_in: numOfCheckIns.count(:user_id, distinct: true), img_url: pl.img_url }
              data_array.push(data)
            end
          end
        end

        data_array.sort_by! {|x| [ x[:users_check_in] ] }
        data_array.reverse!

        factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
        query = factual.table("global").geo("$circle" => {"$center" => [params[:latitude], params[:longitude]], "$meters" => 1000})

        if query.present?
          if hiveapplication.app_type.include? "Food"
            query.each do |q|
              if q["category_labels"].present?
                q["category_labels"].each do |category|
                  if category.include? "Food and Dining"
                    data = { name: q["name"], latitude: q["latitude"], longitude: q["longitude"], address: q["address"], source: 3, user_id: nil, username: nil, source_id: q["factual_id"] }
                    factual_data_array.push(data)
                  end
                end
              end
            end
          else
            query.each do |q|
              data = { name: q["name"], latitude: q["latitude"], longitude: q["longitude"], address: q["address"], source: 3, user_id: nil, username: nil, source_id: q["factual_id"] }
              factual_data_array.push(data)
            end
          end

          data_array.each do |da|
            factual_data_array.each do |fda|
              factual_data_array.delete(fda) if da[:name] == fda[:name]
            end
          end

          data_array = data_array + factual_data_array

          render json: data_array
        else
          render json: data_array
        end
      else
        render json: { error_msg: "Invalid application key" }, status: 400
      end
    else
      render json: { error_msg: "Params latitude, longitude and application key must be presented" }, status: 400
    end
  end

  def information
    if params[:place_id].present? and params[:year].present?
      users_array = [ ]
      visit = 0

      number_of_times_visited_users_array = [ ]
      count = 1

      place = Place.find(params[:place_id])
      user_last_checked_in = Checkinplace.where(place_id: params[:place_id], user_id: current_user.id)
      place_checked_in = Checkinplace.where(place_id: params[:place_id])
      user_check_in = Checkinplace.where(place_id: params[:place_id], user_id: current_user.id)
      user_last_checked_in = user_last_checked_in.last.created_at if user_last_checked_in.present?

      if user_check_in.present?
        user_check_in.each do |uci|
          visit = visit + 1 if uci.created_at.year == params[:year].to_i
        end
      end

      place_checked_in.each do |pci|
        users_array.push(pci.user_id) unless users_array.include?(pci.user_id)
      end

      users_array.each do |ua|
        user = User.find(ua)
        data = { user_id: ua, username: user.username, times_visited: user.checkinplaces.where(place_id: params[:place_id]).count }
        number_of_times_visited_users_array.push(data)
      end

      user =  number_of_times_visited_users_array.select { |s| s[:user_id] == current_user.id }
      place_information = { place_id: place.id, place_name: place.name, place_latitude: place.latitude, place_longitude: place.longitude, place_address: place.address, last_checked_in: user_last_checked_in, total_people: users_array.count, num_of_visits: visit, user: user }

      render json: place_information
    else
      render json: { status: false }
    end
  end

  def top_venue_users
    if params[:place_id].present?
      place = Checkinplace.where(place_id: params[:place_id])
      user_array = [ ]
      number_of_times_visited_array = [ ]
      number_of_times_visited_users_array = [ ]

      place.each do |pl|
        user_array.push(pl.user_id) unless user_array.include?(pl.user_id)
      end
      user_array.each do |ua|
        user = User.find(ua)

        number_of_times_visited_array.push(user.checkinplaces.where(place_id: params[:place_id]).count)
        data = { user_id: ua, username: user.username, times_visited: user.checkinplaces.where(place_id: params[:place_id]).count}

      end
      checked_in_times = number_of_times_visited_array.sort!.reverse
      first_place = number_of_times_visited_users_array.select { |c| c[:times_visited] == checked_in_times[0] }
      second_place = number_of_times_visited_users_array.select { |c| c[:times_visited] == checked_in_times[1] }
      third_place = number_of_times_visited_users_array.select { |c| c[:times_visited] == checked_in_times[2] }

      if first_place.present? and second_place.present? and third_place.present?
        if first_place.last[:times_visited] == second_place.last[:times_visited] and second_place.last[:times_visited] == third_place.last[:times_visited]
          result = { first_place: first_place.last, second_place: second_place.reverse[1], third_place: third_place.reverse[2] } if first_place.last[:username] == second_place.last[:username] and second_place.last[:username] == third_place.last[:username]
        elsif first_place.last[:times_visited] == second_place.last[:times_visited]
          result = { first_place: first_place.last, second_place: second_place.reverse[1], third_place: third_place.last } if first_place.last[:username] == second_place.last[:username]
        elsif second_place.last[:times_visited] == third_place.last[:times_visited]
          result = { first_place: first_place.last, second_place: second_place.last, third_place: third_place.reverse[1] } if second_place.last[:username] == third_place.last[:username]
        end
      elsif first_place.present? and second_place.present?
        if first_place.last[:times_visited] == second_place.last[:times_visited]
          if first_place.last[:username] == second_place.last[:username]
            result = { first_place: first_place.last, second_place: second_place.reverse[1], third_place: third_place.last }
          end
        else
          result = { first_place: first_place.last, second_place: second_place.last, third_place: third_place.last }
        end
      else
        result = { first_place: first_place.last, second_place: second_place.last, third_place: third_place.last }
      end

      render json: result
    end
  end

  def currently_active
    if params[:place_id].present?

      active_users_array = [ ]

      places = Checkinplace.select(:user_id).uniq.where(:place_id=>params[:place_id])
      places.each do |ua|
        time_allowance = Time.now - 1000.minutes.ago
        user = User.find(ua.user_id)
        check_in = user.checkinplaces.where(place_id: params[:place_id]).last
        time_difference = Time.now - check_in.created_at

        if time_difference < time_allowance
          data = { user_id: user.id, username: user.username }
          active_users_array.push(data)
        end
      end

      render json: active_users_array
    else
      render json: { status: false }
    end
  end

  data = [ ]
  def within_location
    data = [ ]
    if params[:latitude].present? and params[:longitude].present? and params[:radius].present? and params[:keyword].present?

      factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
      p "factual data"
      query = factual.table("global").geo("$circle" => {"$center" => [params[:latitude], params[:longitude]], "$meters" => params[:radius]}).search(params[:keyword])

      #testquery = factual.table("places-us").geo("$circle" => {"$center" => [34.058583, -118.416582], "$meters" => 50}).rows
      box = Geocoder::Calculations.bounding_box("#{params[:latitude]},#{params[:longitude]}", params[:radius], {units: :km})
      places = Place.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])

      places.each do |place|
        if place.name.downcase.include?(params[:keyword])
          data.push(place)
        end
      end

      render json: { database: data, factual: query }
    else
      render json: { status: false }
    end
  end

  def within_locality
    if params[:locality].present? and params[:keyword].present?
      factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
      query = factual.table("global").filters("locality" => params[:locality]).search(params[:keyword])

      render json: query
    else
      render json: { status: false }
    end
  end

  def getlatlngbyname
    if params[:place_name].present?
      place = Place.find_by_name(params[:place_name])
      if !place.nil?
        lat = place.latitude
        lng = place.longitude
        add = place.address
      end

      render json: {lat: lat, lng: lng, add: add}
    else
      render json: { status: false }
    end

  end



end