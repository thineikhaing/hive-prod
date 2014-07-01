class Api::TopicsController < ApplicationController
  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveApplication.present?
        #user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?

        if current_user.present?
          #if params[:data].present? and hiveApplication.id != 1
          if hiveApplication.id != 1
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
              topic = Topic.create(title: params[:title], user_id: current_user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, place_id: params[:place_id], data: result, image_url: params[:image_url])
            else
              topic = Topic.create(title: params[:title], user_id: current_user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, place_id: params[:place_id], data: result)
            end

          else
            if params[:image_url].present?
              topic = Topic.create(title: params[:title], user_id: current_user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, place_id: params[:place_id],image_url: params[:image_url])
            else
              topic = Topic.create(title: params[:title], user_id: current_user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, place_id: params[:place_id])
            end
          end
          if hiveApplication.id ==1
            #broadcast new topic creation to hive_channel only
            topic.hive_broadcast
          else
            #broadcast new topic creation to hive_channel and app_channel
            topic.hive_broadcast
            topic.app_broadcast
          end
          render json: { topic: topic }
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

  def getHashValuefromString(data)
    data.sub! '{',''
    data.sub! '}',''
    hash = {}
    data.split(',').each do |pair|
      key,value = pair.split(/:/)
      hash[key] = value
    end
    p hash
    return hash
  end

end
