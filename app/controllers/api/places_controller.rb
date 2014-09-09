class Api::PlacesController < ApplicationController
  def create
    if current_user.present?
      params[:name].present? ? name = params[:name] : name = nil
      params[:category].present? ? category = params[:category] : category = nil
      params[:address].present? ? address = params[:address] : address = nil
      params[:latitude].present? ? latitude = params[:latitude] : latitude = nil
      params[:longitude].present? ? longitude = params[:longitude] : longitude = nil
      params[:locality].present? ? locality = params[:locality] : locality=nil
      #params[:region].present? ? region = params[:region] : region=nil
      params[:place_id].present? ? place_id = params[:place_id] : place_id = nil
      params[:neighbourhood].present? ? neighbourhood = params[:neighbourhood] : neighbourhood=nil
      params[:country].present? ? country = params[:country] : country=nil
      params[:postcode].present? ? postcode = params[:postcode] : postcode=nil
      params[:img_url].present? ? img_url = params[:img_url] : img_url = nil
      #params[:website_url].present? ? website_url= params[:website_url] : website_url = nil
      params[:chain_name].present? ? chain_name = params[:chain_name] : chain_name = nil
      params[:contact_number].present? ? contact_number= params[:contact_number] : contact_number = nil
      params[:source].present? ? source = params[:source] : source = nil
      params[:source_id].present? ? source_id = params[:source_id] : source_id = nil
      params[:app_key].present? ? app_key = params[:app_key] : app_key=nil

      choice="others"
      if app_key.present?
        mealbox_key = ""
        if Rails.env.development?
          mealbox_key = Mealbox_key::Development_Key
        else
          mealbox_key = Mealbox_key::Staging_Key
        end
        choice = "luncheon" if app_key ==  mealbox_key
      end
      #places = Place.create(name: name, category: category, address: address, locality: locality, region: region, neighbourhood: neighbourhood,country: country,postal_code: postcode, website_url: website_url,chain_name: chain_name, contact_number: contact_number,img_url: img_url, source: source, source_id: source_id,user_id: current_user.id, latitude: latitude, longitude: longitude)
      place = Place.new()
      place = place.add_record(name, latitude, longitude, address, source, source_id, place_id, current_user.id, current_user.authentication_token, choice,img_url,category,locality,country,postcode="")
      #Checkinplace.create(place_id: places.id, user_id: current_user.id) if places.present?
      render json: place
    else
      render json: { error_msg: "Params user_id and auth_token must be presented" }
    end
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
      render json: { error_msg: "Params latitude, longitude and radius must be presented" }
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
        render json: { error_msg: "Invalid app_key" }
      end
    else
      render json: { error_msg: "Params latitude, longitude and app_key must be presented" }
    end
  end

end