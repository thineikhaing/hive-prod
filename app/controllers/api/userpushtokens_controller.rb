class Api::UserpushtokensController < ApplicationController

  def create
    if current_user.present? && params[:push_token].present?
      user_push_token = UserPushToken.find_by(:push_token => params[:push_token])
      if user_push_token.present?
        if user_push_token.user_id != current_user.id
          user_push_token.delete if user_push_token.present?
          user_push_token = UserPushToken.create(user_id: current_user.id, push_token: params[:push_token])
        end
      else
        user_push_token = UserPushToken.create(user_id: current_user.id, push_token: params[:push_token])
      end
      render json: { user_push_token: user_push_token }
    else
      render json: { error_msg: "Params user id, authentication token and pusher token must be presented" }, status: 400
    end
  end
end