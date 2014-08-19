class Api::UsersController < ApplicationController

  force_ssl if: :ssl_configured?

  respond_to :json

  def ssl_configured?
    !Rails.env.development?
  end


  def create_anonymous_user
    if User.find_by_device_id(params[:device_id]).present?
      render json: { status: false }

    else
      user = User.create!(device_id: params[:device_id], password: Devise.friendly_token)
      user.token_expiry_date= Date.today + 6.months
      user.save!
      p user
      render json: { user: user }
    end
  end

  def sign_up
    user = User.find_by_authentication_token(params[:auth_token])
    if current_user.present?
      if user.id == current_user.id
        checkEmail = User.find_by_email(params[:email])
        var = [ ]

        if checkEmail.nil?
          user.email = params[:email]
          user.password = params[:password]
          user.password_confirmation = params[:password]
          user.token_expiry_date= Date.today + 6.months
          user.save!

          user_account = UserAccount.create(user_id: user.id, account_type: "hive", linked_account_id: user.id,priority: 0)
          render json: { :user => user, :user_account => user_account, :success => 10 }, status: 200

        else
          var.push(11)
          render json: { :error => var }, status: 400 # Email already exist
        end
      end
    end
  end

  def verify_user_account
    if params[:auth_token].present? & params[:push_token]
      user = User.find_by_authentication_token(params[:auth_token])
      if user.present? & current_user.present?
        if user.id == current_user.id
          user_pusher =  UserPushToken.find_by(:user_id => user.id, :push_token => params[:push_token])
          if user_pusher.present?
            render json: { :user => user, :user_push_token => user_pusher}
          else
            render json:{:status=> false}
          end
        end
      else
        render json:{:status=> false}
      end
    end

  end

  def sign_in
    if params[:email].present? and params[:password].present?
      user = User.find_by_email(params[:email])
      if user.present?
        if user.valid_password?(params[:password])
            user_accounts = UserAccount.where(:user_id => user.id)
            render json: { :user => user_accounts, user_accounts: user_accounts, :success => 20 }, status: 200
        else
          var.push(22)
          render json: { :error => var }, status: 400 # User password wrong
        end
      else
        var.push(21)
        render json: { :error => var }, status: 400 # User email doesn't exist
      end
    end
  end

  def facebook_login
    if params[:fb_id].present?
      var = [ ]
      user = User.find (current_user.id)
      fb_account = UserAccount.find_all_by_account_type_and_linked_account_id("facebook",params[:fb_id])
      if fb_account.present?
        #user_accounts = UserAccount.where(:user_id => user.id)
        #render json: { :user => user,  :user_accounts => user_accounts, :success => 40 }, status: 200
        if fb_account.user_id == user.id
          user_accounts = UserAccount.where(:user_id => user.id)
          render json: { :user => user,  :fb_exists => true, :user_accounts => user_accounts, :success => 40 }, status: 200
        else
          var.push (41)
          render json: { :error => var }, status: 400
        end
      else
        account = UserAccount.new
        new_account = UserAccount.create(user_id: user.id,account_type: "facebook", priority: 0, linked_account_id: params[:fb_id])
        render json: { :user => user,  :fb_exists => true,:user_accounts => user_accounts, :success => 40 }, status: 200
      end
    end
  end

  def user_info
    if current_user.present?
      user = User.find(current_user.id)
      choice = "summary" #default to summary
      if params[:choice].present?
        choice = params[:choice]
      end
      topic_info = user.user_topic_retrival(choice)
      render json: topic_info
    else
      render json:{:status=> false}
    end
  end

  def favourite_user
    if params[:fav_user_id].present? and params[:choice].present? and current_user.present?
      current_user.favourite_user(current_user, params[:user_id], params[:choice])

      render json: { status: true }
    else
      render json: { status: false }
    end
  end

  private

  def user_params
    p "user param is called"
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role, :point, :honor_rating, :created_at, :data, :device_id)
  end


end
