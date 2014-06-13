class Api::UsersController < ApplicationController
  def create_anonymous_user
    if User.find_by_device_id(params[:device_id]).present?
      render json: { status: false }
    else
      user = User.create!(device_id: params[:device_id], password: Devise.friendly_token)

      render json: user
    end
  end
end
