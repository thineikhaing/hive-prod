class Api::TopicsController < ApplicationController
  def create
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      if hiveApplication.present?
        #p @user
        #user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?
        topic = Topic.create(title: params[:title], user_id: my_current_user.id, topic_sub_type: params[:topic_sub_type], hiveapplication_id: hiveApplication.id)

        render json: topic
      end
    else
      render json: { status: false }
    end
  end
end
