class Api::UsersController < ApplicationController
  def create_anonymous_user
    User.create!(device_id: "12345", password: Devise.friendly_token)

    render json: User.search_data("Hive")
  end
end
