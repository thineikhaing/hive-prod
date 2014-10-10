class Api::TopicsController < ApplicationController
  #before_filter :restrict_access

  def create
    if params[:app_key].present?
      p params
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
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
          p data
          p result
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
          p "before enviroment"
          if Rails.env.development?
            p "enviroment"
            carmmunicate_key = Carmmunicate_key::Development_Key
          elsif Rails.env.staging?
            p "staging"
            carmmunicate_key = Carmmunicate_key::Staging_Key
          else
            p "production"
            carmmunicate_key = Carmmunicate_key::Production_Key
          end
          p carmmunicate_key

          if hiveapplication.api_key == carmmunicate_key  and topic.present?
            if params[:users_to_push].present?
              #broadcast to selected user group
              p "params[:users_to_push]"
              p params[:users_to_push]
              if Rails.env.development?
                topic.notify_carmmunicate_msg_to_selected_users_Dev(params[:users_to_push], true)
              else
                topic.notify_carmmunicate_msg_to_selected_users_Dev(params[:users_to_push], true)
                topic.notify_carmmunicate_msg_to_selected_users_Adhoc(params[:users_to_push], true)
              end
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
  #private
  #def restrict_access
  #  hiveapplication = HiveApplication.find_by(api_key: params[:api_key])
  #  render json: {error_msg: "unauthorized access"} unless hiveapplication
  #end

end
