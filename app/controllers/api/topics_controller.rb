class Api::TopicsController < ApplicationController
  #before_filter :restrict_access

  def create
    if params[:app_key].present?
      p hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      tag = Tag.new
      if hiveapplication.present?

        if check_banned_profanity(params[:title])
          user = User.find(current_user.id)
          user.profanity_counter += 1
          user.offence_date = Time.now
          user.save!
        end

        place_id = nil
        #check the place_id presents
        if params[:place_id]
          place_id = params[:place_id].to_i
        else
          #create place first if the place_id is null
          place = Place.create_place_by_lat_lng(params[:latitude], params[:longitude],current_user)

          if place.present?
            place_id = place.id
            Checkinplace.create(place_id: place.id, user_id: current_user.id)
          end

        end

        if current_user.present?
          data = getHashValuefromString(params[:data]) if params[:data].present?
          #get all extra columns that define in app setting
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
                result.merge!(data.extract! (key))
              end
            else
              result = defined_Fields
            end
          end
          result = nil unless result.present?
          params[:likes].present? ? likes = params[:likes].to_i : likes = 0
          params[:dislikes].present? ? dislikes = params[:dislikes].to_i : dislikes = 0
          params[:topic_sub_type].present? ? topic_sub_type = params[:topic_sub_type] :  topic_sub_type = 0
          params[:special_type].present? ? special_type = params[:special_type] : special_type = 0
          #check the profanity
          if params[:image_url].present?
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type:topic_sub_type, hiveapplication_id: hiveapplication.id, unit: params[:unit], value: params[:value],place_id: place_id, data: result, image_url: params[:image_url], width: params[:width], height: params[:height], special_type: special_type,likes: likes, dislikes: dislikes)
            topic.delay.topic_image_upload_job  if params[:topic_type]== Topic::IMAGE.to_s
          else
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: topic_sub_type, hiveapplication_id: hiveapplication.id, unit: params[:unit], value: params[:value], place_id: place_id, data: result, special_type: special_type,likes: likes, dislikes: dislikes)
          end

          #create post if param post_content is passed
          if topic.present? and params[:post_content].present?
            post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, place_id: place_id) if params[:post_type] == Post::TEXT.to_s
            #comment out as there is no image post for luncheon
            #post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, img_url: params[:img_url], width: params[:width], height: params[:height], place_id: place_id) if params[:post_type] == Post::IMAGE.to_s  or params[:post_type] == Post::AUDIO.to_s
          end

          #create tag
          tag.add_record(topic.id, params[:tag], Tag::NORMAL) if params[:tag].present?  and topic.present?
          tag.add_record(topic.id, params[:locationtag], Tag::LOCATION) if params[:locationtag].present?  and topic.present?

          if Rails.env.development?
            carmmunicate_key = Carmmunicate_key::Development_Key
            p favr_key = Favr_key::Development_Key
          elsif Rails.env.staging?
            carmmunicate_key = Carmmunicate_key::Staging_Key
            p favr_key = Favr_key::Staging_Key
          else
            carmmunicate_key = Carmmunicate_key::Production_Key
            p favr_key = Favr_key::Production_Key
          end

          if hiveapplication.api_key == carmmunicate_key  and topic.present?
            if params[:users_to_push].present?
              #broadcast to selected user group
                topic.notify_carmmunicate_msg_to_selected_users(params[:users_to_push], true)
            else
              #broadcast users within 5km/10km
              topic.notify_carmmunicate_msg_to_nearby_users
            end
          end
          #increase like and dislike count

          if likes > 0
            ActionLog.create(action_type: "like", type_id: topic.id, type_name: "topic", action_user_id: current_user.id) if topic.present?
          end
          if dislikes > 0
            ActionLog.create(action_type: "dislike", type_id: topic.id, type_name: "topic", action_user_id: current_user.id) if topic.present?
          end

          if hiveapplication.id ==1
            #broadcast new topic creation to hive_channel only
            topic.hive_broadcast
          elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1
            #All Applications under Herenow except Hive
            topic.hive_broadcast
            topic.app_broadcast_with_content
          else
            #broadcast new topic creation to hive_channel and app_channel
            topic.hive_broadcast
            topic.app_broadcast
          end

          if hiveapplication.id ==1 #Hive Application
            render json: { topic: JSON.parse(topic.to_json()), profanity_counter: current_user.profanity_counter}
          elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1 #All Applications under Herenow except Hive
            render json: { topic: JSON.parse(topic.to_json(content: true)), profanity_counter: current_user.profanity_counter}
          else #3rd party App
            render json: { topic: JSON.parse(topic.to_json()), profanity_counter: current_user.profanity_counter}
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
    (params[:topic_type].present? && params[:topic_type].to_i== Topic::FAVR)  ? state = Topic::OPENED : state = Topic::DEFAULT
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

    hiveapplication = HiveApplication.find_by_app_name('Favr')
    topic.hiveapplication_id = hiveapplication.id
    topic.save

    p "save hive app id"

    if topic.save
      if (topic.topic_type == Topic::FAVR) && user.present?
        user.point -= points
        user.save!
        add_favr_action_delay_job(topic.id)

      end

      current_user = User.find_by_authentication_token(params[:auth_token])
      post = Post.create(content: title, topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude)
      if post.save
        if topic.topic_type == Topic::IMAGE
          post2 = Post.create(content: params[:img_url], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::IMAGE, height: params[:height], width: params[:width])
          post2.delay.image_upload_delayed_job(params[:img_url])
          history.create_record("post", post2.id, "create", topic.id)
        end

        #if topic.topic_type == Topic::LUNCHEON
        #  post2 = Post.create(content: params[:img_url], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::IMAGE, height: params[:height], width: params[:width])
        #  post2.delay.image_upload_delayed_job(params[:img_url])
        #  post3 = Post.create(content: params[:extra_content], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::TEXT)
        #  history.create_record("post", post2.id, "create", topic.id)
        #  history.create_record("post", post3.id, "create", topic.id)
        #
        #  if params[:promo].present?
        #    post4 = Post.create(content: params[:promo_content], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::TEXT)
        #    history.create_record("post", post4.id, "create", topic.id)
        #  end
        #
        #  if params[:coshoot].present?
        #    post5 = Post.create(content: params[:coshoot_img_url], topic_id: topic.id, user_id: params[:coshoot_user_id], latitude: topic.latitude, longitude: topic.longitude, post_type: Post::IMAGE, height: params[:coshoot_height], width: params[:coshoot_width])
        #    post5.delay.image_upload_delayed_job(params[:coshoot_img_url])
        #    history.create_record("post", post5.id, "create", topic.id)
        #  end
        #end

        if topic.topic_type == Topic::FAVR
          post2 = Post.create(content: params[:extra_content], topic_id: topic.id, user_id: current_user.id, latitude: topic.latitude, longitude: topic.longitude, post_type: Post::TEXT)
          history.create_record("post", post2.id, "create", topic.id)
        end
        topic.update_attributes(radius: params[:radius]) if params[:radius].present? and params[:beacon].present?
        topic.flare if params[:flare].present?

       # history.create_record("topic" , topic.id , "create" , nil )
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
        topic.reload
        topic.overall_broadcast

        if check_profanity
          current_user.profanity_counter += 1
          current_user.offence_date = Time.now
          current_user.save!
        end

        check_profanity = false

        render json: { topic: topic, profanity_counter: current_user.profanity_counter, offence_date: current_user.offence_date }
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

          topic.delete

          render json: { status: true }
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
        topic.update_attributes(:title => params["title"], :image_url => params["image_url"].present? ? params["image_url"] : topic.image_url, :data => data)
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

  def favr_topics_by_user
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

      owner_favrs = Topic.where(:user_id => user.id, :topic_type => Topic::FAVR)
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
      render json: { user_points:user.points, user_positive_honor: user.positive_honor, user_negative_honor: user.negative_honor, user_honored_count: user.honored_times , topics: topic_lists, actions: actions,my_requests: myrequests, my_tasks:mytasks}
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

  def honor_to_owner
    if params[:action_id].present? && params[:auth_token] && params[:honor]
      lat = params[:latitude]
      lng = params[:longitude]
      temp_id = params[:temp_id]
      doer_user = User.find_by_authentication_token(params[:auth_token])
      last_favr_action = Favraction.find(params[:action_id].to_i)
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
          post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,last_favr_action.id,post_special_type)
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

  def user_rating
    if params[:user_id].present? and params[:topic_id].present?
      check_like = Actionlog.where(type_name: "topic", type_id: params[:topic_id], type_action: "like", action_user_id: params[:user_id]).count
      check_dislike = Actionlog.where(type_name: "topic", type_id: params[:topic_id], type_action: "dislike", action_user_id: params[:user_id]).count

      render json: { likes: check_like, dislikes: check_dislike }
    end
  end


  # *********** for Socal ***********

  def start_favr(topic_id, user_id, temp_id, lat,lng)
    user = User.find(user_id)
    action_topic = Topic.find(topic_id)

    if (user.id == action_topic.user_id)
      #err doer and owner user_id should not be the same
      render json: {err_message: "owner of favr topic cannot be the doer"}
    else
      unless action_topic.nil?
        if action_topic.state == Topic::OPENED && action_topic.topic_type == Topic::FAVR
          favr_action = Favraction.new
          favr_action = favr_action.create_record(topic_id,user.id,Favraction::DOER_STARTED,user.id)
          if favr_action.present?
            action_topic.state = Topic::IN_PROGRESS
            action_topic.save!
            title = user.username + " has started favr request"
            create_user = User.find_by_username("FavrBot")
            post = Post.new
            new_post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::DOER_STARTED)
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
            action = {action_id: favr_action.id,topic_id:favr_action.topic_id,status: favr_action.status,doer_id:favr_action.doer_user_id,doer_name: doer_name,post_id: post_id, post_content: post_content, post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer, honor_to_owner: favr_action.honor_to_owner,user_id: favr_action.user_id,created_at:favr_action.created_at,updated_at:favr_action.updated_at}
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
        if action_topic.state == Topic::IN_PROGRESS && action_topic.topic_type == Topic::FAVR
          if favr_action.present?
            favr_action.status = Favraction::DOER_FINISHED
            favr_action.user_id = user.id
            favr_action.save!
            action_topic.state = Topic::FINISHED
            action_topic.save!
            title = user.username + " has finished favr request"
            create_user = User.find_by_username("FavrBot")
            post = Post.new
            new_post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::DOER_FINISHED)
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

    users= User.find(action_topic.user_id)

    if user.data.present?
      hash_array = user.data
      device_id = hash_array["device_id"] if  hash_array["device_id"].present?
      to_device_id.push(device_id)
    end


    if action_topic.present?

      if Rails.env.production?
        appID = PushWoosh_Const::FV_P_APP_ID
      elsif Rails.env.staging?
        appID = PushWoosh_Const::FV_S_APP_ID
      else
        appID = PushWoosh_Const::FV_D_APP_ID
      end

      @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}


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
        if action_topic.state == Topic::FINISHED && action_topic.topic_type == Topic::FAVR
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
          new_post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_ACKNOWLEDGED)

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
        elsif (action_topic.topic_type == Topic::FAVR)
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
            new_post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_ACKNOWLEDGED)

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
        if action_topic.state == Topic::FINISHED && action_topic.topic_type == Topic::FAVR
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

          data = {
              user_id: doer_user.id,
              points: doer_user.points
          }

          Pusher["favr_channel"].trigger  "update_user_points", data


          ranking = get_honor_rank(honor)
          title = user.username + " has rejected and rated the " + doer_user.username.to_s + " * " +ranking + " * "
          create_user = User.find_by_username("FavrBot")
          post = Post.new

          post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_REJECTED)

          action_topic.state = Topic::REJECTED
          action_topic.save!

          favr_action.status = Favraction::OWNER_REJECTED
          favr_action.user_id = user.id
          favr_action.honor_to_doer = honor
          favr_action.save!

          post2 = Post.new
          reason_title = "reason to reject: " +reason
          temp_id = temp_id + "1"
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
        elsif (action_topic.state == Topic::TASK_EXPIRED || action_topic.state == Topic::EXPIRED)  && action_topic.topic_type == Topic::FAVR

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
          post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id,Post::OWNER_REJECTED)

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
      if action_topic.state == Topic::REJECTED && action_topic.topic_type == Topic::FAVR
        action_topic.state = Topic::OPENED
        time = action_topic.valid_end_date

        t = time + ((action_topic.given_time.to_i+2)*60)

        action_topic.valid_end_date = t
        action_topic.save!

        title = user.username + " has reopened"
        create_user = User.find_by_username("FavrBot")

        post = Post.new
        post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REOPENED)

        if post.present?
          topic_points = action_topic.points
          topic_free_points= action_topic.free_points
          total_points = topic_points + topic_free_points
          half_points = (total_points/2.0).ceil

          point_difference = free_points.to_i-half_points

          if (point_difference>0)
            action_topic.points = topic_points  +  points.to_i
            action_topic.free_points = point_difference + free_points.to_i
          else
            action_topic.points =  topic_points  - (point_difference).abs + points.to_i
            action_topic.free_points = free_points.to_i
          end
          action_topic.save!

          user.points -= points.to_i
          user.save!
        end

        #action_topic.update_event_broadcast
        render json: {topic: action_topic}
      elsif action_topic.state == Topic::TASK_EXPIRED && action_topic.topic_type == Topic::FAVR
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
              post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REOPENED)

              render json: {topic: action_topic}
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

        time = action_topic.valid_end_date
        #t = time + ((extended_time.to_i+10)*60)
        t = time + ((extended_time.to_i+2)*60)
        action_topic.valid_end_date = t
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
        post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,favr_action.id)
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
          post = post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,last_favr_action.id,post_special_type)
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
      if action_topic.state == Topic::REJECTED && action_topic.topic_type == Topic::FAVR
        action_topic.state = Topic::REVOKED
        action_topic.save!

        total_points = action_topic.points + action_topic.free_points
        half_point = (total_points/2.0).ceil
        remaining_point = total_points- half_point
        if(remaining_point >= action_topic.points)
          user.points += action_topic.points
        else
          user.points  += remaining_point
        end
        user.save!
        #user.update_user_points
        data = {
            user_id: user.id,
            points: user.points
        }

        Pusher["favr_channel"].trigger  "update_user_points", data

        title = user.username + " has revoked the request"
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REVOKED)

        #action_topic.update_event_broadcast
        #render json: {topic: action_topic, action_status: Favraction::OWNER_REVOKED}
      elsif action_topic.state == Topic::TASK_EXPIRED && action_topic.topic_type == Topic::FAVR
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
              post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REVOKED)
            end
            #action_topic.update_event_broadcast
            render json: {topic: action_topic, action_status: Favraction::OWNER_REVOKED}
          end
        end
      elsif action_topic.state == Topic::OPENED && action_topic.topic_type == Topic::FAVR
        #action_record = Favraction.where(:topic_id => action_topic.id).order("id desc")
        action_topic.state = Topic::REVOKED
        action_topic.save!

        user.points += action_topic.points
        user.save!
        #user.update_user_points

        data = {
            user_id: user.id,
            points: user.points
        }

        Pusher["favr_channel"].trigger  "update_user_points", data

        title = user.username + " has revoked the request"
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_record(title, action_topic.id, create_user.id, Post::TEXT.to_s, lat, lng,temp_id,0,0,true,-1,Post::OWNER_REVOKED)


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
        job.delete
        Delayed::Job.enqueue FavrActionJob.new(topic_id),:priority => 0,:run_at => time_diff.minutes.from_now
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
    job =Delayed::Job.enqueue FavrActionJob.new(topic_id),:priority => 0,:run_at => time_diff.minutes.from_now
  end

  def add_favr_task_job(favr_action_id)
    action = Favraction.find(favr_action_id)
    topic = Topic.find(action.topic_id)
    p topic
    p topic.given_time
    #endtime = topic.given_time.to_i + 10
    endtime = topic.given_time.to_i + 2
    p endtime
    job =Delayed::Job.enqueue FavrTaskJob.new(favr_action_id),:priority => 0,:run_at => endtime.minutes.from_now
  end

  def add_favr_task_reminder_job(favr_action_id)
    action = Favraction.find(favr_action_id)
    topic = Topic.find(action.topic_id)
    endtime = topic.given_time.to_i
    p endtime
    job =Delayed::Job.enqueue FavrTaskReminderJob.new(favr_action_id),:priority => 0,:run_at => endtime.minutes.from_now
  end

end
