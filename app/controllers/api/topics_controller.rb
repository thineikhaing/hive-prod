class Api::TopicsController < ApplicationController

  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])
      tag = Tag.new

      if hiveApplication.present?
        #user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?
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

          params[:likes].present? ? likes = params[:likes].to_i : likes = 0
          params[:dislikes].present? ? dislikes = params[:dislikes].to_i : dislikes = 0

          #check the profanity
          if params[:image_url].present?
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value],place_id: place_id, data: result, image_url: params[:image_url], width: params[:width], height: params[:height], special_type: params[:special_type],likes: likes, dislikes: dislikes)
            topic.delay.topic_image_upload_job
          else
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value], place_id: place_id, data: result, special_type: params[:special_type],likes: likes, dislikes: dislikes)
          end
          post = nil
          if topic.present? and params[:post_content].present?
            post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, place_id: place_id) if params[:post_type] == Post::TEXT.to_s
            post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, img_url: params[:img_url], width: params[:width], height: params[:height], place_id: place_id) if params[:post_type] == Post::IMAGE.to_s
          end

          tag.add_record(topic.id, params[:tag], Tag::NORMAL) if params[:tag].present?  and topic.present?
          tag.add_record(topic.id, params[:locationtag], Tag::LOCATION) if params[:locationtag].present?  and topic.present?

          if likes > 0
            ActionLog.create(action_type: "like", type_id: topic.id, type_name: "topic", action_user_id: current_user.id) if topic.present?
          end

          if dislikes > 0
            ActionLog.create(action_type: "dislike", type_id: topic.id, type_name: "topic", action_user_id: current_user.id) if topic.present?
          end

          if hiveApplication.id ==1
            #broadcast new topic creation to hive_channel only
            topic.hive_broadcast
          else
            #broadcast new topic creation to hive_channel and app_channel
            topic.hive_broadcast
            topic.app_broadcast
          end
          if post.present?
            render json: { topic: topic, post:post}
          else
            render json: { topic: topic}
          end

        else
          render json: { status: false }
        end
      else
        render json: { status: false }
      end
    else
      render json: { status: false }
    end
  end

  def topic_liked
    if (params[:topic_id].present? && params[:choice].present?)
      topic = Topic.find(params[:topic_id])
      action_status = topic.user_add_likes(current_user, params[:topic_id], params[:choice])
      topic.reload

      render json: { topic: topic, action_status: action_status }
    else
      render json: { status: false }
    end
  end

  def topic_offensive
    if params[:topic_id].present?
      topic = Topic.find(params[:topic_id])
      topic.user_offensive_topic(current_user, params[:topic_id], topic)
      topic.reload

      render json: { topic: topic }
    else
      render json: { status: false }
    end
  end

  def topic_favourited
    if params[:topic_id].present? && params[:choice].present?
      topic = Topic.find(params[:topic_id])
      topic.user_favourite_topic(current_user, params[:topic_id], params[:choice])
      render json: { status: true }
    else
      render json: { status: false }
    end
  end

  def topics_by_ids
    if params[:app_key].present? and params[:topic_ids].present?
      app = HiveApplication.find_by_api_key(params[:app_key])
      if app.present?
        arr_topic_ids = eval(params[:topic_ids]) #convert string array into array
        topics = Topic.where(:id => arr_topic_ids)
        render json: { topics: topics }
      else
        render json: { status: false}
      end

    else
      render json: { status: false }
    end
  end

  def delete
    if params[:topic_id].present? and params[:app_key].present?
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveapplication.present?
        topic = Topic.find(params[:topic_id])
        if topic.present?
          topic.remove_records
          if hiveapplication.id ==1
            topic.delete_event_broadcast_hive
          else
            topic.delete_event_broadcast_hive
            topic.delete_event_broadcast_other_app
          end
          #topic.delete_event_broadcast
          topic.delete

          render json: { status: true }
        else
          render json: { status: false }
        end
      else
        render json: { status: false }
      end
    else
      render json: { status: false }
    end
  end

end
