class Api::TopicsController < ApplicationController
  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      if hiveApplication.present?
        user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?

        if user.present?
          topic = Topic.create(title: params[:title], user_id: user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, place_id: params[:place_id])

          render json: { topic: topic }
        else
          p 1
          render json: { status: false }
        end
      else
        p 2
        render json: { status: false }
      end
    else
      p 3
      render json: { status: false }
    end
  end
end
