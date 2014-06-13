class Api::TopicsController < ApplicationController
  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      if hiveApplication.present?
        #user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?

        if current_user.present?

          topic = Topic.create(title: params[:title], user_id: current_user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id, place_id: params[:place_id])

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
end
