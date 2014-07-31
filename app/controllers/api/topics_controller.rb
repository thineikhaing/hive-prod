class Api::TopicsController < ApplicationController

  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveApplication.present?
        #user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?

        place_id = nil
        #check the place_id presents
        factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
        if params[:place_id]
          p "if"
          place_id = params[:place_id].to_i
        else   #create place first if the place_id is null
          p "else"
          query = factual.geocode(params[:latitude],params[:longitude]).first

          if query.present?
            p "query presents"
            if query["address"].present?
              check = Place.find_by_address(query["address"])
              p "check1"
              p check
              check.present? ? place = check : place = Place.create(name: query["address"], latitude: params[:latitude], longitude: params[:longitude], address: query["address"], postal_code: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
            elsif query["locality"].present?

              check = Place.find_by_address("Somewhere in #{query["locality"]}")
              p "check2"
              p check
              check.present? ? place = check : place = Place.create(name: "Somewhere in #{query["locality"]}", latitude: params[:latitude], longitude: params[:longitude], address: "Somewhere in #{query["locality"]}", postal_code: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
            end
          else
            p "query does not present"
            geocoder = Geocoder.search("#{params[:latitude]},#{params[:longitude]}").first

            if geocoder.present? and geocoder.country.present?
              p "present"
              check = Place.find_by_address("Somewhere in #{geocoder.country}")
              check2 = Place.find_by_address("Somewhere in the world")

              check.present? ? place = check : place = Place.create(name: "Somewhere in #{geocoder.country}", latitude: params[:latitude], longitude: params[:longitude], address: "Somewhere in #{geocoder.country}", source: Place::UNKNOWN, user_id: current_user.id)
            else
              p "we are the world"
              check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: params[:latitude], longitude: params[:longitude], address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
            end
          end

          if place.present?
            place_id = place.id
          end
        end

        if current_user.present?
          #if params[:data].present? and hiveApplication.id != 1
          #if hiveApplication.id != 1
          data = getHashValuefromString(params[:data]) if params[:data].present?

          #get all extra columns that define in app setting
          appAdditionalField = AppAdditionalField.where(:app_id => hiveApplication.id, :table_name => "Topic")
          if appAdditionalField.present?
            defined_Fields = Hash.new
            appAdditionalField.each do |field|
              defined_Fields[field.additional_column_name] = nil
            end
            #get all extra columns that define in app setting against with the params data
            if data.present?
              data = defined_Fields.deep_merge(data)
              result = Hash.new
              defined_Fields.keys.each do |key|
                result.merge!(data.extract! (key))
              end
            else
              result = defined_Fields
            end
          end
          result = nil unless result.present?
          p result
          if params[:image_url].present?
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value],place_id: place_id, data: result, image_url: params[:image_url], width: params[:width], height: params[:height])
          else
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value], place_id: place_id, data: result)
          end

          #else
          #  if params[:image_url].present?
          #    topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value], place_id: place_id,image_url: params[:image_url], width: params[:width], height: params[:height])
          #  else
          #    topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value], place_id: place_id)
          #  end
          #end
          if hiveApplication.id ==1
            #broadcast new topic creation to hive_channel only
            topic.hive_broadcast
          else
            #broadcast new topic creation to hive_channel and app_channel
            topic.hive_broadcast
            topic.app_broadcast
          end
          render json: { topic: topic}
        else
          p "1"
          render json: { status: false }
        end
      else
        p "2"
        render json: { status: false }
      end
    else
      p "3"
      render json: { status: false }
    end
  end
end
