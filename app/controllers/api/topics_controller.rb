class Api::TopicsController < ApplicationController

  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveApplication.present?
        #user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?

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

          if params[:image_url].present?
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value],place_id: place_id, data: result, image_url: params[:image_url], width: params[:width], height: params[:height], special_type: params[:special_type])
            topic.delay.topic_image_upload_delayed_job(params[:image_url])
          else
            topic = Topic.create(title: params[:title], user_id: current_user.id, topic_type: params[:topic_type], topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, unit: params[:unit], value: params[:value], place_id: place_id, data: result, special_type: params[:special_type])
          end
          post = nil
          if topic.present? and params[:post_content].present?
            post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, place_id: place_id) if params[:post_type] == Post::TEXT.to_s
            post = Post.create(content: params[:post_content], post_type: params[:post_type],  topic_id: topic.id, user_id: current_user.id, img_url: params[:img_url], width: params[:width], height: params[:height], place_id: place_id) if params[:post_type] == Post::IMAGE.to_s
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

end
