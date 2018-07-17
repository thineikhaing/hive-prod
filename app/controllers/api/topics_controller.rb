class Api::TopicsController < ApplicationController
  #before_action :restrict_access

  def create
    if params[:app_key].present?
      p hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      title = params[:title]
      tag = Tag.new
      if hiveapplication.present?

        place_id = nil
        #check the place_id presents
        if params[:place_id]
          place_id = params[:place_id].to_i
        else
          #create place first if the place_id is null
          if params[:latitude].present?
           place = Place.create_place_by_lat_lng(params[:latitude], params[:longitude],current_user)
          # else
          #   place = Place.create_place_by_lat_lng(1.352083, 103.819836,current_user)
          end


          if place.present?
            place_id = place.id
            Checkinplace.create(place_id: place.id, user_id: current_user.id)
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
        # params[:place_id].present? ? place_id = params[:place_id].to_i :  place_id = nil

        category = ""
        locality=""
        country=""
        postcode=""
        img_url = nil
        choice="others"

        start_id = 0
        end_id = 0

        # start_place = place.add_record("Marina South Pier MRT", "1.2713367", "103.8628598", "", 0, 0, nil, 1, "GsdaMJmx2uRjPcVsmuff", nil,nil,nil,nil,nil,nil)

        if params[:start_place_id] || params[:start_longitude]  || params[:start_longitude]  || params[:start_source_id]
            place = Place.new
            start_place = place.add_record(start_name, start_latitude, start_longitude, start_address, start_source, start_source_id, start_place_id, current_user.id, current_user.authentication_token, choice,img_url,category,locality,country,postcode)
            # p "start place info::::"
            start_id = start_place[:place].id
            start_place[:place].name

            if params[:latitude].to_i == 0 && params[:longitude].to_i
              place_id = start_id
            end
        end

        if params[:end_place_id] || params[:end_longitude]  || params[:end_longitude]  || params[:end_source_id]
          end_place = place.add_record(end_name, end_latitude, end_longitude, end_address, end_source, end_source_id, end_place_id, current_user.id, current_user.authentication_token, choice,img_url,category,locality,country,postcode)
          # p "end place info::::"
          end_id = end_place[:place].id
          end_place[:place].name

          if params[:latitude].to_i == 0 && params[:longitude].to_i
            place_id = start_id
          end
        end



        data = params[:data] if data.present?
        data = data.delete('\\"') if data.present?
        p "data hash value"
        p data
        if current_user.present?

          data = getHashValuefromString(data) if data.present?
          appAdditionalField = AppAdditionalField.where(:app_id => hiveapplication.id, :table_name => "Topic")
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
                p "merge value"
                p result.merge!(data.extract! (key))
              end

            else
              result = defined_Fields
            end

            p result
            if params[:departure_time].present?
              result["depature_time"]= params[:departure_time]
              result["arrival_time"]= params[:arrival_time]
            end

            if params[:transport_type].present?
              result["transport_type"]= params[:transport_type]
              result["color"]= params[:color]
            end
          end


          result = nil unless result.present?
          params[:likes].present? ? likes = params[:likes].to_i : likes = 0
          params[:dislikes].present? ? dislikes = params[:dislikes].to_i : dislikes = 0
          params[:topic_sub_type].present? ? topic_sub_type = params[:topic_sub_type] :  topic_sub_type = 0
          params[:special_type].present? ? special_type = params[:special_type] : special_type = 0
          #check the profanity

          topic_user = current_user.id
          if params[:topic_type].to_i == 10
            topic_user = 1
          end

          if params[:lta_id].to_i > 0
            sg_accident = SgAccidentHistory.find(params[:lta_id])
            special_type = sg_accident.type
            start_id = sg_accident.place_id
            end_id = sg_accident.place_id
            place_id = sg_accident.place_id
          end

          if params[:image_url].present?
            topic = Topic.create(title:title, user_id: topic_user, topic_type: params[:topic_type],start_place_id: start_id, end_place_id: end_id,
                                 topic_sub_type:topic_sub_type, hiveapplication_id: hiveapplication.id, unit: params[:unit],
                                 value: params[:value],place_id: place_id, data: result, image_url: params[:image_url],
                                 width: params[:width], height: params[:height], special_type: special_type,likes: likes, dislikes: dislikes)

            topic.delay.topic_image_upload_job  if params[:topic_type]== Topic::IMAGE.to_s
          else
            topic = Topic.create(title:title, user_id: topic_user, topic_type: params[:topic_type] ,start_place_id: start_id , end_place_id: end_id,
                                 topic_sub_type: topic_sub_type, hiveapplication_id: hiveapplication.id, unit: params[:unit],
                                 value: params[:value], place_id: place_id, data: result, special_type: special_type,likes: likes, dislikes: dislikes)
          end
          topic.save

          if params[:created_by]
            topic.created_at = params[:created_by]
            topic.save
          end

          #create post if param post_content is passed
          if topic.present? and params[:post_content].present?
            p "Post create"
            post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, place_id: place_id) if params[:post_type] == Post::TEXT.to_s
            #comment out as there is no image post for luncheon
            #post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, img_url: params[:img_url], width: params[:width], height: params[:height], place_id: place_id) if params[:post_type] == Post::IMAGE.to_s  or params[:post_type] == Post::AUDIO.to_s
          end

          #create tag
          tag.add_record(topic.id, params[:tag], Tag::NORMAL) if params[:tag].present?  and topic.present?
          tag.add_record(topic.id, params[:locationtag], Tag::LOCATION) if params[:locationtag].present?  and topic.present?

          if Rails.env.development?
            carmmunicate_key = Carmmunicate_key::Development_Key
            favr_key = Favr_key::Development_Key
            round_key = RoundTrip_key::Development_Key
          elsif Rails.env.staging?
            carmmunicate_key = Carmmunicate_key::Staging_Key
            favr_key = Favr_key::Staging_Key
            round_key = RoundTrip_key::Staging_Key
          else
            carmmunicate_key = Carmmunicate_key::Production_Key
            favr_key = Favr_key::Production_Key
            round_key = RoundTrip_key::Production_Key
          end

          if hiveapplication.api_key == carmmunicate_key  and topic.present?
            p "notify to carmic user"
            if !params[:users_to_push].nil?
              #broadcast to selected user group
                topic.notify_carmmunicate_msg_to_selected_users(params[:users_to_push], true)
            else
              #broadcast users within 5km/10km
              topic.notify_carmmunicate_msg_to_nearby_users
            end
          end

           p "check to share"
          p params[:shared_rt]
          if params[:shared_rt].present? and hiveapplication.api_key == round_key
            p "notify to rt users"
             topic.notify_roundtrip_users
          end

          #increase like and dislike count

          if likes > 0
            ActionLog.create(action_type: "like", type_id: topic.id, type_name: "topic", action_user_id: current_user.id) if topic.present?
          end
          if dislikes > 0
            ActionLog.create(action_type: "dislike", type_id: topic.id, type_name: "topic", action_user_id: current_user.id) if topic.present?
          end
          p "hiveapplication id:::"
          p hiveapplication.id
          if hiveapplication.id ==1
            p "broadcast new topic creation to hive_channel only"
            topic.hive_broadcast
          elsif hiveapplication.devuser_id ==1 and hiveapplication.id!=1
            p "All Applications under Herenow except Hive"
            topic.hive_broadcast
            topic.app_broadcast_with_content
          else
            p "broadcast new topic creation to hive_channel and app_channel"
            topic.hive_broadcast
            topic.app_broadcast
          end

          if hiveapplication.id ==1 #Hive Application
            render json: { topic: JSON.parse(topic.to_json()), profanity_counter: current_user.profanity_counter}
          elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1 #All Applications under Herenow except Hive
            render json: { topic: JSON.parse(topic.to_json(content: true)),post:post, profanity_counter: current_user.profanity_counter}
          else #3rd party App
            render json: { topic: JSON.parse(topic.to_json()), profanity_counter: current_user.profanity_counter}
        end

          if check_banned_profanity(topic.title)
            user = User.find(current_user.id)
            user.profanity_counter += 1
            user.offence_date = Time.now
            user.save!
          end

        else
          render json: { error_msg: "Params user_id and auth_token must be presented" }
        end
      else
        render json: { error_msg: "Invalid app_key" }
      end
    else
      render json: { error_msg: "Param app_key must be presented" }
    end
  end

  def check_transit_topic
    if params[:title]
      topic = Topic.where(title: params[:title], )
      if topic.present?
        render json: {topic: JSON.parse(topic.to_json()), status: 200}
      else
        render json: {status: 201,message: 'create new transit topic'}
      end
    end
  end

  def favtopic_create
    tag = Tag.new
    history = Historychange.new
    factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    topic = ""
    place = ""
    check_profanity = false

    params[:extra_info].present? ? extra_info = params[:extra_info] : extra_info = ""
    params[:valid_start_date].present? ? valid_start_date = DateTime.parse(params[:valid_start_date]) : valid_start_date = nil
    params[:valid_end_date].present? ? valid_end_date = DateTime.parse(params[:valid_end_date]) : valid_end_date = nil
    params[:likes].present? ? likes = params[:likes].to_i : likes = 0
    params[:dislikes].present? ? dislikes = params[:dislikes].to_i : dislikes = 0
    params[:given_time].present? ? given_time = params[:given_time].to_i : given_time = 0  #in minutes



    if check_banned_profanity(params[:title])
      check_profanity = true
    end

    #title = filter_profanity(params[:title])
    check_title = params[:title]
    title = params[:title]
    special_type = Topic.check_special_type(params[:flare], params[:beacon], params[:sticky], params[:promo], params[:coshoot],params[:question],params[:errand])
    user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?
    params[:points].present? ? points = params[:points].to_i : points = 0
    params[:free_points].present? ? free_points = params[:free_points].to_i : free_points = 0


    state = Topic::OPENED


    (params[:checker].present?)  ? checker = params[:checker].to_i : checker = Topic::CHECKER_DEFAULT
    (params[:title_indexes].present?)  ? title_indexes = params[:title_indexes] : title_indexes = ""
    if params[:place_id]
      if user.present?
        topic = Topic.create(title: title, topic_type: params[:topic_type], user_id: user.id, special_type: special_type, place_id: params[:place_id], extra_info: extra_info, valid_start_date: valid_start_date, valid_end_date: valid_end_date, likes: likes, dislikes: dislikes, points: points,free_points: free_points,state: state,title_indexes: title_indexes,checker: checker,given_time: given_time)
        if likes > 0
          Actionlog.create(type_action: "like", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end

        if dislikes > 0
          Actionlog.create(type_action: "dislike", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end
      else
        topic = Topic.create(title: title, topic_type: params[:topic_type], user_id: current_user.id, special_type: special_type, place_id: params[:place_id], extra_info: extra_info, valid_start_date: valid_start_date, valid_end_date: valid_end_date, likes: likes, dislikes: dislikes,points: points,free_points: free_points,state: state,title_indexes: title_indexes,checker: checker,given_time: given_time)

        if likes > 0
          Actionlog.create(type_action: "like", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end

        if dislikes > 0
          Actionlog.create(type_action: "dislike", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end
      end
    else
      query = factual.geocode(params[:latitude],params[:longitude]).first

      if query.present?
        if query["address"].present?
          check = Place.find_by_address(query["address"])
          check.present? ? place = check : place = Place.create(name: query["address"], latitude: params[:latitude], longitude: params[:longitude], address: query["address"], postcode: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
        elsif query["locality"].present?
          check = Place.find_by_address("Somewhere in #{query["locality"]}")
          check.present? ? place = check : place = Place.create(name: "Somewhere in #{query["locality"]}", latitude: params[:latitude], longitude: params[:longitude], address: "Somewhere in #{query["locality"]}", postcode: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
        end
      else

        geocoder = Geocoder.search("#{params[:latitude]},#{params[:longitude]}").first

        if geocoder.present? and geocoder.country.present?
          check = Place.find_by_address("Somewhere in #{geocoder.country}")
          check2 = Place.find_by_address("Somewhere in the world")

          check.present? ? place = check : place = Place.create(name: "Somewhere in #{geocoder.country}", latitude: params[:latitude], longitude: params[:longitude], address: "Somewhere in #{geocoder.country}", source: Place::UNKNOWN, user_id: current_user.id)
        else
          check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: params[:latitude], longitude: params[:longitude], address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
        end
      end



      if user.present?
        topic = Topic.create(title: title, topic_type: params[:topic_type], user_id: user.id, special_type: special_type, place_id: place.id, extra_info: extra_info, valid_start_date: valid_start_date, valid_end_date: valid_end_date, likes: likes, dislikes: dislikes, points: points,free_points: free_points,state: state,title_indexes: title_indexes,checker: checker,given_time: given_time)

        if likes > 0
          Actionlog.create(type_action: "like", type_id: topic.id, type_name: "topic",  action_user_id: user.id)
        end

        if dislikes > 0
          Actionlog.create(type_action: "dislike", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end
      else
        topic = Topic.create(title: title, topic_type: params[:topic_type], user_id: current_user.id, special_type: special_type, place_id: place.id, extra_info: extra_info, valid_start_date: valid_start_date, valid_end_date: valid_end_date, likes: likes, dislikes: dislikes, points: points,free_points: free_points,state: state,title_indexes: title_indexes,checker: checker,given_time: given_time)

        if likes > 0
          Actionlog.create(type_action: "like", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end

        if dislikes > 0
          Actionlog.create(type_action: "dislike", type_id: topic.id, type_name: "topic", action_user_id: user.id)
        end
      end
    end


    if topic.save

      if (topic.topic_type == Topic::FAVR) && user.present?
        user.points -= points
        user.daily_points -= free_points
        user.save!
        add_favr_action_delay_job(topic.id)

      end

      current_user = User.find_by_authentication_token(params[:auth_token])
      post = Post.create(content: title, topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude)
      if post.save
        if topic.topic_type == Topic::IMAGE
          post2 = Post.create(content: params[:img_url], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::IMAGE, height: params[:height], width: params[:width])
          post2.delay.image_upload_delayed_job(params[:img_url])
          #history.create_record("post", post2.id, "create", topic.id)
          history.type_name = 'post'
          history.type_id = post2.id
          history.type_action = 'create'
          history.parent_id = topic.id
          history.save
        end

        if topic.topic_type == Topic::FAVR
          post2 = Post.create(content: params[:extra_content], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::TEXT)
          #history.create_record("post", post2.id, "create", topic.id)

          history= Historychange.new

          history.type_name = 'post'
          history.type_id = post2.id
          history.type_action = 'create'
          history.parent_id = topic.id
          history.save

        end
        p "current user"

        p current_user
        p "dev user ::::"
        p @devuser

        # @devuser.update_attributes(params.require(:devuser).permit(:username, :email, :password, :password_confirmation, :verified, :email_verification_code, :hiveapplication_id, :data))

        # topic.update_attributes(radius: params[:radius])
        if params[:radius].present? and params[:beacon].present?
          topic.radius = params[:radius]
          topic.save
        end

        topic.flare if params[:flare].present?

       # HISTORY.create_record("topic" , topic.id , "create" , nil )
        #(type_name: type, type_id: type_id, type_action: type_action, parent_id: parent_id)

        history= Historychange.new
        history.type_action = 'create'
        history.type_name = 'topic'
        history.type_id = topic.id
        history.parent_id = nil
        history.save

        tag.create_record(topic.id, params[:tag], Tag::NORMAL) if params[:tag].present?
        tag.create_record(topic.id, params[:locationtag], Tag::LOCATION) if params[:locationtag].present?

        #history.create_record("post", post.id, "create", topic.id)
        #history.create_record("topic", topic.id, "update", nil)
        #post.broadcast

        hiveapplication = HiveApplication.find_by_app_name('Favr')
        topic.hiveapplication_id = hiveapplication.id
        topic.save
        p "save hive app id"

        topic.reload
        topic.overall_broadcast

        if check_profanity
          current_user.profanity_counter += 1
          current_user.offence_date = Time.now
          current_user.save!
        end

        check_profanity = false

        #avatar = Topic.get_avatar(topic.user.username)

        avatar = User.find_by_id(topic.user_id).avatar_url
        if avatar.nil?
          username = User.find_by_id(topic.user_id).username

          if username  == "FavrBot"
            avatar = "assets/Avatars/Chat-Avatar-Admin.png"
          else
            avatar = Topic.get_avatar(username)
          end

        end


        render json: { topic: topic,avatar_url: avatar, profanity_counter: current_user.profanity_counter, offence_date: current_user.offence_date, daily_points: topic.user.daily_points }
      else
        topic.delete

        render json: { status: false }
      end
    else
      render json: { status: false }
    end
  end

  def topic_liked
    if (params[:topic_id].present? && params[:choice].present?)
      topic = Topic.find_by_id(params[:topic_id])
      if topic.present?
        action_status = topic.user_add_likes(current_user, params[:topic_id], params[:choice])
        p action_status

        topic.reload

        hiveapplication = HiveApplication.find(topic.hiveapplication_id)

        if hiveapplication.id ==1 #Hive Application
          render json: { topic: JSON.parse(topic.to_json()), action_status: action_status}
        elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1 #All Applications under Herenow except Hive

          render json: { topic: JSON.parse(topic.to_json(content: true)), action_status: action_status}
        else #3rd party App
          render json: { topic: JSON.parse(topic.to_json()), action_status: action_status}
        end
      else
        render json: { error_msg: "Invalid topic_id" }
      end

    else
      render json: { error_msg: "Params topic_id and choice must be presented" }
    end
  end

  def topic_offensive
    if params[:topic_id].present?
      topic = Topic.find_by_id(params[:topic_id])
      if topic.present?
        topic.user_offensive_topic(current_user, params[:topic_id], topic)
        topic.reload

        hiveapplication = HiveApplication.find(topic.hiveapplication_id)

        if hiveapplication.id ==1 #Hive Application
          render json: { topic: JSON.parse(topic.to_json())}
        elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1 #All Applications under Herenow except Hive
          render json: { topic: JSON.parse(topic.to_json(content: true))}
        else #3rd party App
          render json: { topic: JSON.parse(topic.to_json())}
        end
      else
        render json: {error_msg: "Invalid topic_id"}
      end
    else
      render json: { error_msg: "Param topic_id must be presented" }
    end
  end

  def topic_favourited
    if params[:topic_id].present? && params[:choice].present?
      topic = Topic.find_by_id(params[:topic_id])
      if topic.present?
        topic.user_favourite_topic(current_user, params[:topic_id], params[:choice])
        render json: { status: true }
      else
        render json: { error_msg: "Invalid topic_id" }
      end
    else
      render json: { error_msg: "Params topic_id and choice must be presented" }
    end
  end

  def topics_by_ids
    if params[:app_key].present? and params[:topic_ids].present?
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveapplication.present?
        arr_topic_ids = eval(params[:topic_ids]) #convert string array into array
        topics = Topic.where(:id => arr_topic_ids)
        if hiveapplication.id ==1 #Hive Application
          render json: { topics: JSON.parse(topics.to_json())}
        elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1 #All Applications under Herenow except Hive
          render json: { topics: JSON.parse(topics.to_json(content: true))}
        else #3rd party App
          render json: { topics: JSON.parse(topics.to_json())}
        end
      else
        render json: { error_msg: "Invalid app_key" }
      end
    else
      render json: { error_msg: "Params app_key and topic_ids must be presented" }
    end
  end

  def delete
    if params[:topic_id].present? and params[:app_key].present?
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveapplication.present?
        topic = Topic.find_by_id(params[:topic_id])
        if topic.present?
          topic.remove_records

          if hiveapplication.id ==1
          #if hiveapplication.devuser_id ==1
            topic.delete_event_broadcast_hive
          elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1
            topic.delete_event_broadcast_hive
            topic.delete_event_broadcast_other_app_with_content
          else
            topic.delete_event_broadcast_hive
            topic.delete_event_broadcast_other_app
          end

          #delete file from S3 if topic type is IMAGE AUDIO VIDEO
          bucket_name = ""
          file_name=""
          if topic.topic_type == Topic::IMAGE
            file_name = topic.image_url
            if Rails.env.development?
              bucket_name = AWS_Bucket::Image_D
            elsif Rails.env.staging?
              bucket_name = AWS_Bucket::Image_S
            else
              bucket_name = AWS_Bucket::Image_P
            end
            topic.delete_S3_file(bucket_name, file_name,topic.topic_type)
          elsif topic.topic_type == Topic::AUDIO
            file_name = topic.image_url
            if Rails.env.development?
              bucket_name = AWS_Bucket::Audio_D
            elsif Rails.env.staging?
              bucket_name = AWS_Bucket::Audio_S
            else
              bucket_name = AWS_Bucket::Audio_P
            end
            topic.delete_S3_file(bucket_name, file_name,topic.topic_type)
          end

          #topic.delete_event_broadcast

          if topic.hiveapplication_id ==1 #Hive Application
                                          #if hiveapplication.devuser_id == 1
            topic.delete_event_broadcast_hive
          else
            topic.delete_event_broadcast_hive
            topic.delete_event_broadcast_other_app
          end
          topics = []
          if current_user.present?
            topics = Topic.where(user_id: current_user.id)
          end
          topic.delete


          render json: { status: true,topics: topics }
        else
          render json: { error_msg: "Invalid topic_id" }
        end
      else
        render json: { error_msg: "Invalid app_key" }
      end
    else
      render json: { error_msg: "Params topic_id and app_key must be presented" }
    end
  end

  def topic_by_image
     if params[:image_url].present? and params[:app_key].present?
       hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
       if hiveapplication.present?
         topic = Topic.find_by_image_url(params[:image_url])
         if topic.present?
           render json: { topic: JSON.parse(topic.to_json(content: true))}
         end
       else
         render json: { error_msg: "Invalid app_key" }
       end
     else
       render json: { error_msg: "Params app_key and image_url must be presented" }
     end
  end

  def topics_within_two_points

    s_latitude = params[:s_latitude]
    s_longitude = params[:s_longitude]

    e_latitude = params[:e_latitude]
    e_longitude = params[:e_longitude]

    hive_app = HiveApplication.find_by_api_key(params[:app_key])

    if hive_app.present?

      session[:user] = current_user


     topics = Place.nearest_topics_within_start_and_end(s_latitude, s_longitude, e_latitude,e_longitude , nil, hive_app.id)

     topics = topics.sort {|x,y| y["created_at"]<=>x["created_at"]}

     initial_topic = Topic.find_by_topic_sub_type(2)
     topics.prepend(initial_topic)

     tcount = topics.count rescue '0'
     p "get nearest topics"
     render json: {topics:topics, topic_count: tcount, status: "nearest topics within start and end"}
    else
      render json: {status: "Params app_key must be presented"}
    end
  end

  #private
  #def restrict_access
  #  hiveapplication = HiveApplication.find_by(api_key: params[:api_key])
  #  render json: {error_msg: "unauthorized access"} unless hiveapplication
  #end

#for now juice app only used this following 2 api's

  def get_topic
    if params[:topic_id].present? and params[:app_key].present?
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveapplication.present?
        topic = Topic.find_by_id(params[:topic_id])
        if topic.present?
          render json: { topic: JSON.parse(topic.to_json(content: true))}
        end
      else
        render json: { error_msg: "Invalid app_key" }
      end
    else
      render json: { error_msg: "Params app_key and topic_ids must be presented" }
    end
  end

  def get_alltopic
    topic = Topic.all.where("hiveapplication_id != 4").order(:hiveapplication_id)
    if topic.present?
      render json: { topic: JSON.parse(topic.to_json(content: true))}

    else
      render json: { error_msg: "No Topic" }
    end
  end

  def update_topic
    if params[:app_key].present?
      application = HiveApplication.find_by_api_key(params[:app_key])
      #@Topicfields = table_list(params[:app_id], "Topic")
      #save the updated Application information
      if application.present?
        topics = Topic.where('hiveapplication_id = ?', application.id)
        topic = topics.select{|top|  top.id == params[:app_id].to_i}.last
        data = getHashValuefromString(params[:data]) if params[:data].present?
        data["serving"] = data["serving"].present? ? data["serving"] : topic.data["serving"]
        data["ingredients"] = data["ingredients"].present? ? data["ingredients"] : topic.data["ingredients"]
        data["advantages"] = data["advantages"].present? ? data["advantages"] : topic.data["advantages"]
        data["weather"] = data["weather"].present? ? data["weather"] : topic.data["weather"]

        # topic.update_attributes(:title => params["title"], :image_url => params["image_url"].present? ? params["image_url"] : topic.image_url, :data => data)

        topic.title = params["title"]
        topic.image_url = params["image_url"] if params["image_url"].present?
        topic.data = data
        topic.save


        render json: { topic: JSON.parse(topic.to_json(content: true))}
      end
    else
      render json: { error_msg: "Params app_key and topic_ids must be presented" }
    end
  end

  def search
    if params[:title].present?
      topic = Topic.find_by_topic_type_and_title(Topic::WEB, params[:title])
      if topic.present?
        render json: { topic_id: topic.id }
      else
        render json: { topic_id: nil }
      end
    else
      render json: { status: false }
    end
  end

  def topics_by_user
    hive = HiveApplication.find_by_api_key(params[:app_key])

    if hive.present?
      topics = Topic.where(hiveapplication_id: hive.id, user_id: current_user.id)
      user_friend_list = UserFriendList.where(user_id: current_user.id)
      trips = Trip.where(user_id: current_user.id).order('id DESC').last(10)

      if trips.count > 11
        ids = trips.limit(10).order('id DESC').pluck(:id)
        trips.where('id NOT IN (?)', ids).destroy_all
      end

      trip_detail =  []
      trips.each do |trip|
        detail = trip.data["route_detail"]
        # detail = detail.gsub!(/\"/, '\'')
        trip_detail.push(eval(detail))
      end

      posts_topics = []
      if current_user.posts.count > 0
        current_user.posts.map{|pst| posts_topics.push(pst.topic_id)}
      end
      if posts_topics.count > 0
        posts_topics = posts_topics.uniq!
      end

      # a.gsub!(/\"/, '\'')
      #eval(a)

      render json: {trip_detail:trip_detail,
                  topics: topics, posts: posts_topics,
                  topic_count: topics.count,
                    trips: trips, trip_count: trips.count,
                    user_friend_list: user_friend_list,
                    friend_count: user_friend_list.count}, status: 200
    else
      render json: {message: "no topics"}
    end
  end

  def check_user_last_topic
    p "checking user's last topic with transport_type"

    hive_app_key = HiveApplication.find_by_api_key(params[:app_key])
    if hive_app_key.present?
      p user_id = params["user_id"]
      p transport_type = params["transport_type"]
      p user_topics = Topic.where(user_id:user_id)
      if user_topics.nil?
        p "no topic by current user"
        render json: {message: "There is no topic created by the current user"}
      else
        p "topic exist"
        p user_topic = user_topics.where("data->'transport_type'=?",transport_type).last

        render json: {topic: user_topic}, status: 200
      end
    end
  end


  def favr_topics_by_user

    p 'favr_topics_by_user'
    if params[:auth_token].present?
      user = User.find_by_authentication_token(params[:auth_token])
      owner_current_record = []
      doer_current_record = []
      owner_closed_record = []
      doer_closed_record = []
      owner_incomplete_record = []
      doer_incomplete_record = []
      topic_ids = []
      action_ids = []

      #OWNER FAVRS

      owner_favrs = Topic.where(:user_id => user.id)
      if owner_favrs.present?
        owner_favrs.each do |topic|
          if topic.state == Topic::OPENED || topic.state == Topic::IN_PROGRESS || topic.state == Topic::FINISHED
            owner_current_record.push(topic.id)
            topic_ids << topic.id unless topic_ids.include?(topic.id)
          elsif topic.state == Topic::ACKNOWLEDGED
            owner_closed_record.push(topic.id)
            topic_ids << topic.id unless topic_ids.include?(topic.id)
          elsif topic.state == Topic::REVOKED || topic.state == Topic::EXPIRED || topic.state == Topic::TASK_EXPIRED || topic.state == Topic::REJECTED
            favr_actions =  Favraction.where(:topic_id => topic.id)
            owner_incomplete_record.push(topic.id)
            topic_ids << topic.id unless topic_ids.include?(topic.id)
          end
          owner_actions = Favraction.where(:topic_id => topic.id)
          if owner_actions.present?
            owner_actions.each do |action|
              action_ids<< action.id unless action_ids.include? (action.id)
            end
          end
        end
      end

      myrequests= {current: owner_current_record, incomplete: owner_incomplete_record,completed: owner_closed_record}

      # DOER FAVRS
      doer_favrs = Favraction.where(:doer_user_id => user.id)
      if doer_favrs.present?
        doer_favrs.each do |topic|
          if topic.status == Favraction::DOER_STARTED || topic.status == Favraction::COMPLETION_REMINDER_SENT || topic.status == Favraction::DOER_FINISHED
            doer_current_record.push(topic.topic_id)
            topic_ids << topic.topic_id unless topic_ids.include?(topic.topic_id)
          elsif topic.status == Favraction::OWNER_ACKNOWLEDGED || topic.status == Favraction::DOER_RESPONDED_ACK
            doer_closed_record.push(topic.topic_id)
            topic_ids << topic.topic_id unless topic_ids.include?(topic.topic_id)
          end
          action_ids<< topic.id unless action_ids.include? (topic.id)
        end
      end

      doer_incomplete_favrs = Favraction.where(:doer_user_id => user.id,:status => [Favraction::OWNER_REJECTED,Favraction::DOER_RESPONDED_REJ,Favraction::EXPIRED_AFTER_STARTED,Favraction::EXPIRED_AFTER_FINISHED])
      if doer_incomplete_favrs.present?
        doer_incomplete_favrs.each do |favraction|
          doer_incomplete_record << (favraction.topic_id) unless doer_incomplete_record.include? (favraction.topic_id)
          topic_ids << favraction.topic_id unless topic_ids.include?(favraction.topic_id)
        end
      end
      mytasks= {current: doer_current_record, incomplete: doer_incomplete_record,completed: doer_closed_record}

      topic_lists = Topic.where(:id=> topic_ids)

      action_lists = Favraction.where(:id=>action_ids)
      actions=[]
      post_id = -1
      post_content=""
      post_created_at=""
      if action_lists.present?
        action_lists.each do |favraction|
          topic= Topic.find(favraction.topic_id)
          favr_action_id = favraction.id
          last_favr_action_status =  favraction.status.to_i
          doer_id= favraction.doer_user_id
          doer = User.find(doer_id)
          doer_name = doer.username
          unless favraction.post_id.nil?
            post= Post.find(favraction.post_id)
            post_id = post.id
            post_content = post.content
            post_created_at = post.created_at
          end
          honor_to_doer = favraction.honor_to_doer.to_i
          honor_to_owner  = favraction.honor_to_owner.to_i
          actions.push({action_id: favr_action_id,topic_id:topic.id,status: last_favr_action_status,doer_id:doer_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: honor_to_doer, honor_to_owner: honor_to_owner,user_id: favraction.user_id,created_at:favraction.created_at,updated_at:favraction.updated_at})
        end
      end

      render json: {daily_points:user.daily_points, user_points:user.points,
                    user_positive_honor: user.positive_honor, user_negative_honor: user.negative_honor,
                    user_honored_count: user.honored_times , topics: topic_lists, actions: actions,
                    my_requests: myrequests, my_tasks:mytasks}
    end
  end

  def favr_action
    if (params[:action_id].present? || params[:topic_id].present?) && params[:auth_token].present? && params[:action_type].present? && params[:temp_id].present? && params[:latitude].present? && params[:longitude].present?
      params[:topic_id].present? ? topic_id = params[:topic_id].to_i : topic_id = -1
      params[:action_id].present? ? favr_action_id = params[:action_id].to_i : favr_action_id = -1
      user = User.find_by_authentication_token (params[:auth_token])

      p "=========="
      p topic_id
      p favr_action_id
      p params[:action_type]
      p "========="

      if params[:action_type].to_i== Topic::START
        start_favr(topic_id, user.id, params[:temp_id], params[:latitude],params[:longitude])
      elsif params[:action_type].to_i== Topic::FINISH
        finish_favr(favr_action_id, user.id, params[:temp_id], params[:latitude],params[:longitude])
      elsif params[:action_type].to_i== Topic::ACKNOWLEDGE
        acknowledge_favr(favr_action_id, user.id, params[:temp_id], params[:latitude],params[:longitude], params[:honor].to_i)
      elsif params[:action_type].to_i== Topic::REJECT
        reject_favr(favr_action_id, user.id, params[:temp_id], params[:latitude],params[:longitude], params[:honor].to_i, params[:reason])
      elsif params[:action_type].to_i== Topic::REOPEN
        if params[:points].present? && params[:free_points].present?
          reopen_favr(topic_id, user.id,params[:points],params[:free_points], params[:temp_id], params[:latitude],params[:longitude])
        end
      elsif params[:action_type].to_i== Topic::REVOKE
        p "topic revoke"
        revoke_favr_by_owner(topic_id, user.id, params[:temp_id], params[:latitude],params[:longitude])
      elsif params[:action_type].to_i== Topic::EXTEND
        if params[:extended_time].present?
          p "Extended"
          extend_time(favr_action_id, user.id, params[:extended_time].to_i, params[:temp_id], params[:latitude],params[:longitude])
        end
      else
        p "it was something else"
      end

    end
  end

  def user_rating
    if params[:user_id].present? and params[:topic_id].present?
      check_like = Actionlog.where(type_name: "topic", type_id: params[:topic_id], type_action: "like", action_user_id: params[:user_id]).count
      check_dislike = Actionlog.where(type_name: "topic", type_id: params[:topic_id], type_action: "dislike", action_user_id: params[:user_id]).count

      render json: { likes: check_like, dislikes: check_dislike }
    end
  end


  # *********** for Socal ***********

  def start_favr(topic_id, user_id, temp_id, lat,lng)
    p "start favr"
    user = User.find(user_id)
    action_topic = Topic.find(topic_id)

    if (user.id == action_topic.user_id)
      #err doer and owner user_id should not be the same
      render json: {err_message: "owner of favr topic cannot be the doer"}
    else
      unless action_topic.nil?
        p action_topic.state
        if action_topic.state == Topic::OPENED
          p "favr action"
          #favr_action = favr_action.create_record(topic_id,user.id,Favraction::DOER_STARTED,user.id)
          #  Favraction.create(topic_id: topic_id, doer_user_id: doer_user_id, status: status, user_id: user_id)
          #
          favr_action = Favraction.new
          favr_action.topic_id = topic_id
          favr_action.doer_user_id = user.id
          favr_action.status = Favraction::DOER_STARTED
          favr_action.user_id = user_id
          favr_action.save!

          if favr_action.present?
            action_topic.state = Topic::IN_PROGRESS
            action_topic.save!
            title = user.username + " has started favr request"
            create_user = User.find_by_username("FavrBot")

            post = Post.new
            p action_topic.id
            p "action_topic"
            p create_user.id
            p "create user"
            p favr_action.id
            p "Favr action id"

            new_post = post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::DOER_STARTED)
            favr_action.post_id = new_post.id
            favr_action.save!

            extend_favr_action_delay_job(action_topic.id)
            add_favr_task_reminder_job(favr_action.id)
            add_favr_task_job(favr_action.id)

            doer = User.find(favr_action.doer_user_id)
            doer_name = doer.username
            unless favr_action.post_id.nil?
              post= Post.find(favr_action.post_id)
              post_id = post.id
              post_content = post.content
              post_created_at = post.created_at
            end
            p "action"

            p action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,
                        doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id,
                        post_content: post_content, post_created_at: post_created_at,
                        honor_to_doer: favr_action.honor_to_doer, honor_to_owner: favr_action.honor_to_owner,
                        user_id: favr_action.user_id,created_at:favr_action.created_at,updated_at:favr_action.updated_at}

            render json: {topic: action_topic , action: action}
          end
        else
          #topic is not in open state
          render json: {err_message: "Topic status must be OPENED"}
        end
      end
    end
  end

  def finish_favr (favr_action_id, user_id, temp_id, lat,lng)
    user = User.find(user_id)
    favr_action =  Favraction.find(favr_action_id)
    if favr_action.present?
      action_topic = Topic.find(favr_action.topic_id)
      unless action_topic.nil?
        if action_topic.state == Topic::IN_PROGRESS
          if favr_action.present?
            favr_action.status = Favraction::DOER_FINISHED
            favr_action.user_id = user.id
            favr_action.save!
            action_topic.state = Topic::FINISHED
            action_topic.save!
            title = user.username + " has finished favr request"
            create_user = User.find_by_username("FavrBot")
            post = Post.new
            new_post = post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::DOER_FINISHED)
            favr_action.post_id = new_post.id
            favr_action.save!
            remove_favr_task_reminder_job(favr_action_id)
            notify_owner_to_acknowledge(action_topic.id)
            #render json: {topic: action_topic, action_status: Favraction::DOER_FINISHED}
            doer = User.find(favr_action.doer_user_id)
            doer_name = doer.username
            unless favr_action.post_id.nil?
              post= Post.find(favr_action.post_id)
              post_id = post.id
              post_content = post.content
              post_created_at = post.created_at
            end
            action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer, honor_to_owner: favr_action.honor_to_owner,user_id: favr_action.user_id,created_at:favr_action.created_at,updated_at:favr_action.updated_at}
            render json: {topic: action_topic , action: action}
          else
            render json: {err_message: "Topic status must be IN_PROGRESS"}
          end
        else
          #topic is not in in_progress state
          render json: {err_message: "Topic status must be IN_PROGRESS"}
        end
      end
    end
  end

  def notify_owner_to_acknowledge(topic_id)
    p "inside urban airship function"
    p topic_id

    action_topic = Topic.find(topic_id)
    p action_topic
    user = User.find_by_username("FavrBot")
    p action_topic.user_id.to_s
    p "before urban airship"
    user_to_push=[]
    user_to_push.push(action_topic.user_id.to_s)
    p user_to_push

    user= User.find(action_topic.user_id)

    to_device_id = []
    if user.data.present?
      hash_array = user.data
      device_id = hash_array["device_id"] if  hash_array["device_id"].present?
      to_device_id.push(device_id)
    end

     p "to device id"
     p to_device_id

    if action_topic.present?

      if Rails.env.production?
        appID = PushWoosh_Const::FV_P_APP_ID
      elsif Rails.env.staging?
        appID = PushWoosh_Const::FV_S_APP_ID
      else
        appID = PushWoosh_Const::FV_D_APP_ID
      end

      @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

      p "Device id"
      p to_device_id

      notification_options = {
          send_date: "now",
          badge: "1",
          sound: "default",
          content:{
              fr:"Your favr request is finished",
              en:"Your favr request is finished"
          },
          data:{
              topic_id:action_topic.id
          },
          devices: to_device_id
      }

      p options = @auth.merge({:notifications  => [notification_options]})
      options = {:request  => options}

      full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
      url = URI.parse(full_path)
      req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
      req.body = options.to_json
      con = Net::HTTP.new(url.host, url.port)
      con.use_ssl = true

      p request = con.start {|http| http.request(req)}
      p "pushwoosh"

    end
  end

  def get_honor_rank(honor)
    if honor < 1
      return "Fail"
    elsif honor < 2
      return "B"
    elsif honor < 3
      return "A"
    else
      return "A+"
    end
  end

  def acknowledge_favr (favr_action_id, user_id, temp_id, lat,lng,honor)
    user = User.find(user_id)
    favr_action = Favraction.find(favr_action_id)
    if favr_action.present?
      action_topic = Topic.find(favr_action.topic_id)
      unless action_topic.nil?
        if action_topic.state == Topic::FINISHED
          favr_action.status = Favraction::OWNER_ACKNOWLEDGED
          favr_action.user_id = user.id
          favr_action.honor_to_doer = honor
          favr_action.save!

          doer_user = User.find_by_id(favr_action.doer_user_id)
          action_topic.state = Topic::ACKNOWLEDGED
          action_topic.save!

          #update points
          total_points = action_topic.points + action_topic.free_points
          doer_user.points += total_points
          doer_user.honored_times +=1
          if (honor>0)
            doer_user.positive_honor += honor
          else
            doer_user.negative_honor += (-1 * honor)
          end
          doer_user.save!
          #doer_user.update_user_points
          data = {
              user_id: doer_user.id,
              points: doer_user.points
          }

          Pusher["favr_channel"].trigger  "update_user_points", data

          ranking = get_honor_rank(honor)
          title = user.username + " has acknowledged and rated the " + doer_user.username.to_s  + " * " + ranking  + " * "
          create_user = User.find_by_username("FavrBot")
          post = Post.new
          new_post = post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_ACKNOWLEDGED)

          favr_action.post_id = new_post.id
          favr_action.save!

          remove_favr_action_delay_job(favr_action.topic_id)
          remove_favr_task_reminder_job(favr_action.id)
          remove_favr_task_job(favr_action.id)

          #render json: {topic: action_topic, action_status: Favraction::OWNER_ACKNOWLEDGED}
          doer = User.find(favr_action.doer_user_id)
          doer_name = doer.username
          unless favr_action.post_id.nil?
            post= Post.find(favr_action.post_id)
            post_id = post.id
            post_content = post.content
            post_created_at = post.created_at
          end
          action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer, honor_to_owner: favr_action.honor_to_owner,user_id: favr_action.user_id,created_at:favr_action.created_at,updated_at:favr_action.updated_at}
          render json: {topic: action_topic , action: action}
          #elsif (action_topic.state == Topic::TASK_EXPIRED || action_topic.state == Topic::EXPIRED) && action_topic.topic_type == Topic::FAVR
          #topic must be with expired_after_completed sts
        else
          if (favr_action.status == Favraction::EXPIRED_AFTER_FINISHED)
            favr_action.status= Favraction::OWNER_ACKNOWLEDGED
            favr_action.user_id = user.id
            favr_action.honor_to_doer = honor
            favr_action.save!

            doer_user = User.find_by_id(favr_action.doer_user_id)
            action_topic.state = Topic::ACKNOWLEDGED
            action_topic.save!

            #update points
            total_points = action_topic.points + action_topic.free_points
            half_point = (total_points/2.0).ceil
            remaining_point = total_points- half_point
            doer_user.points += remaining_point
            doer_user.honored_times +=1
            if (honor>0)
              doer_user.positive_honor += honor
            else
              doer_user.negative_honor += (-1 * honor)
            end
            doer_user.save!
            #doer_user.update_user_points
            data = {
                user_id: doer_user.id,
                points: doer_user.points
            }

            Pusher["favr_channel"].trigger  "update_user_points", data

            ranking = get_honor_rank(honor)
            title = user.username + " has acknowledged and rated the " + doer_user.username.to_s  + " * " + ranking + " * "
            create_user = User.find_by_username("FavrBot")
            post = Post.new
            new_post = post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_ACKNOWLEDGED)

            favr_action.post_id = new_post.id
            favr_action.save!

            remove_favr_action_delay_job(favr_action.topic_id)
            remove_favr_task_reminder_job(favr_action.id)
            remove_favr_task_job(favr_action.id)

            #render json: {topic: action_topic, action_status: Favraction::OWNER_ACKNOWLEDGED}
            doer = User.find(favr_action.doer_user_id)
            doer_name = doer.username
            unless favr_action.post_id.nil?
              post= Post.find(favr_action.post_id)
              post_id = post.id
              post_content = post.content
              post_created_at = post.created_at
            end
            action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer, honor_to_owner: favr_action.honor_to_owner,user_id: favr_action.user_id,created_at:favr_action.created_at,updated_at:favr_action.updated_at}
            render json: {topic: action_topic , action: action}
          else
            render json: {err_message: "Topic state must be FINISHED/ action status must be EXPIRED_AFTER_FINISHED"}
          end
        end
      end
    else
      render json: {err_message: "Invalid favr_action_id"}
    end
  end

  def reject_favr(favr_action_id, user_id, temp_id, lat,lng,honor, reason)
    user = User.find(user_id)
    favr_action = Favraction.find(favr_action_id)
    if favr_action.present?
      action_topic = Topic.find(favr_action.topic_id)

      unless action_topic.nil?
        if action_topic.state == Topic::FINISHED
          doer_user = User.find_by_id(favr_action.doer_user_id)
          #update points
          total_points = action_topic.points + action_topic.free_points
          p "tootal point is "
          p total_points
          half_point = (total_points.to_d/2.0).ceil
          p "half point is"
          p half_point
          doer_user.points += half_point
          doer_user.honored_times +=1
          if (honor>0)
            doer_user.positive_honor += honor
          else
            doer_user.negative_honor += (-1 * honor )
          end

          doer_user.save!
          p "doer's point is"
          p doer_user.points
          #doer_user.update_user_points

          #remaining_point = total_points- half_point
          #if remaining_point >= action_topic.points
          #  user.points += action_topic.points
          #else
          #  user.points += remaining_point
          #end


          data = {
              user_id: doer_user.id,
              points: doer_user.points
          }

          Pusher["favr_channel"].trigger  "update_user_points", data


          ranking = get_honor_rank(honor)
          title = user.username + " has rejected and rated the " + doer_user.username.to_s + " * " +ranking + " * "
          create_user = User.find_by_username("FavrBot")
          post = Post.new

          post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_REJECTED)

          action_topic.state = Topic::REJECTED
          action_topic.save!

          favr_action.status = Favraction::OWNER_REJECTED
          favr_action.user_id = user.id
          favr_action.honor_to_doer = honor
          favr_action.save!

          post2 = Post.new
          reason_title = "reason to reject: " +reason
          temp_id = temp_id + "1"

          new_post = post2.create_post(reason_title, action_topic.id, user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_REJECTED)

          favr_action.post_id = new_post.id
          favr_action.save!

          remove_favr_task_reminder_job(favr_action.id)
          remove_favr_task_job(favr_action.id)

          doer = User.find(favr_action.doer_user_id)
          doer_name = doer.username
          unless favr_action.post_id.nil?
            post= Post.find(favr_action.post_id)
            post_id = post.id
            post_content = post.content
            post_created_at = post.created_at
          end
          action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,
                    doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id,
                    post_content: post_content, post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer,
                    honor_to_owner: favr_action.honor_to_owner,user_id: favr_action.user_id,created_at:favr_action.created_at,
                    updated_at:favr_action.updated_at}

          p "render topic and action"
          p action_topic
         render json: {topic: action_topic , action: action, test: 'ok'}

          #render json: {topic: action_topic, action_status: Favraction::OWNER_REJECTED, reason_post_id:new_post.id, reason_post_content: new_post.content}


        elsif (action_topic.state == Topic::TASK_EXPIRED || action_topic.state == Topic::EXPIRED)

          doer_user = User.find_by_id(favr_action.doer_user_id)

          #total_points = action_topic.points + action_topic.free_points
          #half_point = (total_points/2).ceil
          #remaining_point = total_points- half_point
          #if remaining_point >= action_topic.points
          #  user.points += action_topic.points
          #else
          #  user.points += remaining_point
          #end


          doer_user.honored_times +=1
          if (honor>0)
            doer_user.positive_honor += honor
          else
            doer_user.negative_honor += (-1 * honor )
          end
          doer_user.save!

          ranking = get_honor_rank(honor)
          title = user.username + " has rejected and rated the " + doer_user.username.to_s  + " * " + ranking + " * "
          create_user = User.find_by_username("FavrBot")
          post = Post.new
          post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_REJECTED)

          #action_topic.state = Topic::EXPIRED
          #action_topic.save!

          favr_action.status = Favraction::OWNER_REJECTED
          favr_action.user_id = user.id
          favr_action.honor_to_doer = honor
          favr_action.save!

          temp_id = temp_id + "1"
          post2 = Post.new
          reason_title = "reason to reject: " +reason
          new_post = post2.create_record(reason_title, action_topic.id, user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_REJECTED)


          favr_action.post_id = new_post.id
          favr_action.save!

          remove_favr_task_reminder_job(favr_action.id)
          remove_favr_task_job(favr_action.id)

          doer = User.find(favr_action.doer_user_id)
          doer_name = doer.username
          unless favr_action.post_id.nil?
            post= Post.find(favr_action.post_id)
            post_id = post.id
            post_content = post.content
            post_created_at = post.created_at
          end
          action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer, honor_to_owner: favr_action.honor_to_owner,user_id: favr_action.user_id,created_at:favr_action.created_at,updated_at:favr_action.updated_at}
          render json: {topic: action_topic , action: action}
          #render json: {topic: action_topic, action_status: Favraction::OWNER_REJECTED, reason_post_id:new_post.id, reason_post_content: new_post.content}
        else
          render json: {err_message: "Topic status must be FINISHED"}
        end
      end
    end
  end

  def reopen_favr(topic_id, user_id, points, free_points, temp_id, lat,lng)
    user = User.find(user_id)
    action_topic = Topic.find(topic_id)
    unless action_topic.nil?
      if action_topic.state == Topic::REJECTED
        action_topic.state = Topic::OPENED
        time = action_topic.valid_end_date

        t = time + ((action_topic.given_time.to_i+2)*60)

        action_topic.valid_end_date = t
        action_topic.save!

        title = user.username + " has reopened"
        create_user = User.find_by_username("FavrBot")

        post = Post.new
        post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REOPENED)
        p "reopen state *******"
        if post.present?

          p topic_points = action_topic.points
          #0
          p topic_free_points= action_topic.free_points
          #2

          p total_points = topic_points + topic_free_points
          #2

          p half_points = (total_points/2.0).ceil
          #1

          p point_difference = free_points.to_i-half_points
          # 0 -1 = -1

          if (point_difference>0)
            p "if point diff is greater than 0"
            p action_topic.points = topic_points  +  points.to_i
            p action_topic.free_points = point_difference + free_points.to_i
          else
            p "if point diff is less than 0"
            #p action_topic.points =  topic_points  - (point_difference).abs + points.to_i

            p action_topic.points =  topic_points + points.to_i

            # topic.points = 1 - (+2) + 2

            if free_points.to_i > 0
              p "topic free point is greater than 0"
              p action_topic.free_points = (total_points/2.0).floor + free_points.to_i

            else
              p "topic free point is equal to 0 or less"
              p action_topic.free_points =  free_points.to_i
            end

          end
          action_topic.save!

          p user.points -= points.to_i
          p user.daily_points -= free_points.to_i
          user.save!
        end

        action_topic.update_event_broadcast
        render json: {topic: action_topic , daily_points: action_topic.user.daily_points}
      elsif action_topic.state == Topic::TASK_EXPIRED
        action_record = Favraction.where(:topic_id => action_topic.id).order("id")
        if action_record.present?
          last_action_record = action_record.last
          if last_action_record.present?
            if last_action_record.status == Favraction::EXPIRED_AFTER_STARTED
              action_topic.state = Topic::OPENED
              time = action_topic.valid_end_date

              t = time + ((action_topic.given_time.to_i+2)*60)

              action_topic.valid_end_date = t
              action_topic.save!

              title = user.username + " has reopened"
              create_user = User.find_by_username("FavrBot")

              post = Post.new
              post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REOPENED)

              render json: {topic: action_topic, daily_points: action_topic.user.daily_points}
            end
          end
        end
      else
        render json: {err_message: "Topic status must be REJECTED/TASK_EXPIRED"}
      end
    else
      render json: {err_message: "Invalid Topic_id"}
    end
  end

  def extend_time(favr_action_id, user_id, extended_time, temp_id, lat,lng)
    user = User.find(user_id)
    favr_action = Favraction.find(favr_action_id)
    action_topic = Topic.find(favr_action.topic_id)
    if favr_action.present?
      p "action topic state"
      p action_topic.state
      if action_topic.state== Topic::IN_PROGRESS
        p  "favr_action.status"
        p favr_action.status
        if favr_action.status==Favraction::COMPLETION_REMINDER_SENT
          endtime = extended_time.to_i
          p endtime
          job =Delayed::Job.enqueue FavrTaskReminderJob.new(favr_action_id),:priority => 0,:run_at => endtime.minutes.from_now
        else
          p "extend favr tak reminder job"
          extend_favr_task_reminder_job(favr_action.id,extended_time.to_i)
        end

        #time = action_topic.valid_end_date
        #t = time + ((extended_time.to_i+2)*60)

        action_topic.valid_end_date = action_topic.valid_end_date +  ((extended_time.to_i+2)*60*10)
        action_topic.save!

        p "before extend favr task job"
        p favr_action.id
        extend_favr_task_job(favr_action.id,extended_time.to_i)
        p "after extend favr task job"
        extend_favr_action_delay_job(favr_action.topic_id,extended_time.to_i)
        p "after favr action delay job"
        title = user.username + " has extended the time for the task "
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post = post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id)
        p post
        render json: {topic: action_topic}
      else
        render json: {err_message: "Topic status must be IN_PROGRESS"}
      end
    else
      render json: {err_message: "Invalid favr_action_id"}
    end
  end

  def honor_to_owner
    if params[:action_id].present? && params[:auth_token] && params[:honor]
      lat = params[:latitude]
      lng = params[:longitude]
      temp_id = params[:temp_id]
      doer_user= User.find_by_authentication_token(params[:auth_token])
      last_favr_action= Favraction.find(params[:action_id].to_i)
      post_special_type = 0
      if last_favr_action.present?
        action_topic = Topic.find(last_favr_action.topic_id)
        last_favr_action.honor_to_owner =   params[:honor].to_i
        if last_favr_action.status == Favraction::OWNER_REJECTED
          last_favr_action.status= Favraction::DOER_RESPONDED_REJ
          post_special_type = Post::DOER_RESPONDED_REJ
        elsif last_favr_action.status== Favraction::OWNER_ACKNOWLEDGED
          last_favr_action.status=Favraction::DOER_RESPONDED_ACK
          post_special_type = Post::DOER_RESPONDED_ACK
        end
        last_favr_action.save!
        if action_topic.present?
          owner_user = User.find(action_topic.user_id)
          if (params[:honor].to_i >0)
            owner_user.positive_honor += params[:honor].to_i
          else
            owner_user.negative_honor += (params[:honor].to_i * -1)
          end
          owner_user.honored_times +=1
          owner_user.save!

          ranking = get_honor_rank(params[:honor].to_i)
          title = doer_user.username + " has rated " + owner_user.username.to_s  + " * " + ranking + " * "
          create_user = User.find_by_username("FavrBot")
          p "before post"
          post = Post.new
          p action_topic
          post = post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,last_favr_action.id,post_special_type)
          p post
        end
        doer_name = doer_user.username
        unless last_favr_action.post_id.nil?
          post= Post.find(last_favr_action.post_id)
          post_id = post.id
          post_content = post.content
          post_created_at = post.created_at
        end
        action = {action_id: last_favr_action.id,topic_id:last_favr_action.topic_id,status: last_favr_action.status,doer_id:last_favr_action.doer_user_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: last_favr_action.honor_to_doer, honor_to_owner: last_favr_action.honor_to_owner,user_id: last_favr_action.user_id,created_at:last_favr_action.created_at,updated_at:last_favr_action.updated_at}
        render json: {topic: action_topic , action: action}
      end

    end
  end

  def revoke_favr_by_owner(topic_id, user_id, temp_id, lat,lng)
    user= User.find(user_id)
    action_topic = Topic.find(topic_id)
    if action_topic.present?
      if action_topic.state == Topic::REJECTED
        action_topic.state = Topic::REVOKED
        action_topic.save!
        p "revoke and calculate user points"
        p total_points = action_topic.points + action_topic.free_points
        p half_point = (total_points/2.0).ceil
        p remaining_point = total_points- half_point

        p "#############"
        if(remaining_point >= action_topic.points)
          p "action topic point"
          user.points += action_topic.points
        else
          p "remaining point"
          user.points  += remaining_point
        end
        user.save!

        p user.points

        #user.update_user_points
        data = {
            user_id: user.id,
            points: user.points
        }

        Pusher["favr_channel"].trigger  "update_user_points", data

        title = user.username + " has revoked the request"
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REVOKED)

        #action_topic.update_event_broadcast
        #render json: {topic: action_topic, action_status: Favraction::OWNER_REVOKED}
      elsif action_topic.state == Topic::TASK_EXPIRED
        action_record = Favraction.where(:topic_id => action_topic.id).order("id")
        if action_record.present?
          last_action_record = action_record.first
          if last_action_record.present?
            if last_action_record.status == Favraction::EXPIRED_AFTER_STARTED
              user.points += action_topic.points
              user.save!
              #user.update_user_points
              data = {
                  user_id: user.id,
                  points: user.points
              }

              Pusher["favr_channel"].trigger  "update_user_points", data

              action_topic.state = Topic::REVOKED
              action_topic.save!

              title = user.username + " has revoked the request"
              create_user = User.find_by_username("FavrBot")
              post = Post.new
              post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REVOKED)
            end
            #action_topic.update_event_broadcast
            render json: {topic: action_topic, action_status: Favraction::OWNER_REVOKED}
          end
        end
      elsif action_topic.state == Topic::OPENED
        #action_record = Favraction.where(:topic_id => action_topic.id).order("id desc")
        action_topic.state = Topic::REVOKED
        action_topic.save!

        if action_topic.points == 0
          user.points += action_topic.free_points
        else
          user.points += action_topic.points
        end

        user.save!
        #user.update_user_points

        p "********** user points **********"
        p user.points

        data = {
            user_id: user.id,
            points: user.points
        }

        Pusher["favr_channel"].trigger  "update_user_points", data

        title = user.username + " has revoked the request"
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REVOKED)

        p "revoke open topic"

        render json: {topic: action_topic, action_status: Favraction::OWNER_REVOKED}


      else
        render json: {err_message: "Topic status must be REJECTED/ OPENED/ EXPIREED_AFTER_STARTED"}
      end
    end
  end

  def remove_favr_action_delay_job(topic_id)
    jobs= Delayed::Job.all
    jobs.each do |job|
      if job.name == "favraction-Topic-#{topic_id}"
        p job.name+ " has been removed from queue"
        job.delete
      end
    end
  end

  def remove_favr_task_job(favr_action_id)
    jobs= Delayed::Job.all
    jobs.each do |job|
      if job.name == "favraction-task-#{favr_action_id}"
        p job.name+ " has been removed from queue"
        job.delete
      end
    end
  end

  def remove_favr_task_reminder_job(favr_action_id)
    jobs= Delayed::Job.all
    jobs.each do |job|
      if job.name == "favraction-task-reminder-#{favr_action_id}"
        p job.name+ " has been removed from queue"
        job.delete
      end
    end
  end

  def extend_favr_action_delay_job(topic_id,extended_time=0)  #timer1 extends
    topic = Topic.find(topic_id)
    jobs= Delayed::Job.all
    jobs.each do |job|
      if job.name == "favraction-Topic-#{topic_id}"
        endtime = job.run_at
        start_time = Time.parse(DateTime.now.to_s)
        time_diff = (TimeDifference.between(start_time, endtime).in_minutes).ceil
        if  extended_time > 0
          #time_diff = time_diff + 10 + extended_time.to_i
          time_diff = time_diff + 2 + extended_time.to_i
        else
          #time_diff = time_diff + 10 +topic.given_time
          time_diff = time_diff + 2 +topic.given_time
        end

        p "time diff extend favr action delay job"

        p time_diff.minutes
        job.delete

        t = Topic.find(topic_id)

        Delayed::Job.enqueue FavrActionJob.new(topic_id),:priority => 0,:run_at => t.valid_end_date
      end
    end
  end

  def extend_favr_task_job(favr_action_id,extended_time) #timer3 extends
    p "inside extend favr task job"
    p favr_action_id
    jobs= Delayed::Job.all
    jobs.each do |job|
      if job.name == "favraction-task-#{favr_action_id}"
        endtime = job.run_at
        start_time = Time.parse(DateTime.now.to_s)
        time_diff = (TimeDifference.between(start_time, endtime).in_minutes).ceil
        p time_diff
        #time_diff = time_diff + 10 + extended_time.to_i
        time_diff = time_diff + 2 + extended_time.to_i
        p time_diff
        job.delete
        p "job has been deleted"
        Delayed::Job.enqueue FavrTaskJob.new(favr_action_id),:priority => 0,:run_at => time_diff.minutes.from_now
      end
    end
    p "outside extend favr task job"
  end

  def extend_favr_task_reminder_job(favr_action_id,extended_time) #timer2 extends
    jobs= Delayed::Job.all
    jobs.each do |job|
      if job.name == "favraction-task-reminde r-#{favr_action_id}"
        endtime = job.run_at
        start_time = Time.parse(DateTime.now.to_s)
        time_diff = (TimeDifference.between(start_time, endtime).in_minutes).ceil
        time_diff = time_diff + extended_time.to_i
        job.delete
        p "favraction-task-reminder is deleted"
        Delayed::Job.enqueue FavrTaskReminderJob.new(favr_action_id),:priority => 0,:run_at => time_diff.minutes.from_now
      end
    end
  end

  def add_favr_action_delay_job(topic_id)
    topic = Topic.find(topic_id)
    start_time = Time.parse(DateTime.now.to_s)
    end_time = Time.parse(topic.valid_end_date.to_s)
    time_diff = (TimeDifference.between(start_time, end_time).in_minutes).ceil

    p "add favr action delay job"
    p "time difference"

    #time_diff.minutes.from_now
    job =Delayed::Job.enqueue FavrActionJob.new(topic_id),:priority => 0,:run_at => time_diff.minutes.from_now
  end

  def add_favr_task_job(favr_action_id)
    action = Favraction.find(favr_action_id)
    topic = Topic.find(action.topic_id)
    p topic
    p topic.given_time
    #endtime = topic.given_time.to_i + 10
    endtime = topic.given_time.to_i + 2

    p "add favr task job"
    p "end time"
    p endtime
    job =Delayed::Job.enqueue FavrTaskJob.new(favr_action_id),:priority => 0,:run_at => endtime.minutes.from_now
  end

  def add_favr_task_reminder_job(favr_action_id)
    action = Favraction.find(favr_action_id)
    topic = Topic.find(action.topic_id)
    endtime = topic.given_time.to_i

    p "add favr task reminder job"
    p "end time"
    p endtime
    job =Delayed::Job.enqueue FavrTaskReminderJob.new(favr_action_id),:priority => 0,:run_at => endtime.minutes.from_now
  end

end


def ok
  sns = AWS::SNS.new(
      access_key_id: "AKIAIJMZ5RLXRO6LJHPQ",
      secret_access_key: "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",
      region: "ap-southeast-1"
  )
  client = sns.client


  begin
    response = client.create_platform_endpoint(
        platform_application_arn: 'arn:aws:sns:ap-southeast-1:378631322826:app/GCM/Roundtrip_S',
        token: device_token
    )
    p endpoint_arn = response[:endpoint_arn]
  rescue => e
    result = e.message.match(/Endpoint(.*)already/)
    if result.present?
      endpoint_arn = result[1].strip
    end
  end

  data = {
      'aps' => {
          'alert' => 'Hi there!',
          'badge' => 1,
          'sound' => 'default'
      }
  }

  ios_endpoint_arn = 'arn:aws:sns:ap-southeast-1:378631322826:endpoint/APNS/Roundtrip_S/1ab611da-e4ec-38cb-8758-f63c63d6f2ce'

# double json encode
  message_json = {
      'APNS' => data.to_json
  }.to_json

  sns.publish(
      target_arn: ios_endpoint_arn,
      message: message_json,
      message_structure: 'json',
      GCM: "okay"
  )

  topic = client.create_topic(name: 'RoundTrip_Topic')
  topic_arn = topic[:topic_arn]

  client.subscribe(
      topic_arn: topic_arn,
      protocol: 'application',
      endpoint: endpoint_arn
  )

  data = {
      'aps' => {
          'alert' => 'Hi there!',
          'badge' => 1,
          'sound' => 'default'
      }
  }

# double json encode
  message_json = {
      'default' => 'Hi there!',
      'APNS' => data.to_json
  }.to_json

  client.publish(
      target_arn: topic_arn,
      message: message_json,
      message_structure: 'json'
  )


  #send noti message to iphone

  sns = Aws::SNS::Client.new
  target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti'


  iphone_notification = {
      aps: {
          alert: "Send message to ios from hive",
          sound: "default",
          badge: 0,
          extra:  {a: 1, b: 2}
      }
  }


  android_notification = {
      data: {
          message: "Send message to android from hive" ,
          badge: 0,
          extra:  {a: 1, b: 2}
      }
  }

  sns_message = {
      default: "Hi there",
      APNS_SANDBOX: iphone_notification.to_json,
      APNS: iphone_notification.to_json,
      GCM: android_notification.to_json
  }.to_json


  noti_message = sns.publish(target_arn: target_topic,
                         message: sns_message, message_structure:"json")


end
