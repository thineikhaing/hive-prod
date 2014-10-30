class Api::MytestController < ApplicationController

  def test
    User.create(email: "ximen@example.com", password: "password", username: "Xi Men Chui Xue", data: {nickname: "East Door Blow Snow", ranked: 1, role: "Force Beater" })
    #User.create(username: "hj", email: "hj@example.com", password: "password")
    render json: "Hi"
  end

  def test2
    users = User.all
    users.each do |u|
      if u.data.present?
         if u.data.has_key?("role") == true
           data_hash = u.data.except("role")
           p data_hash
           u.data = data_hash
           u.save!
         end
      end
    end
    render json: "test2"
  end

  def test3
    User.all.each do |u|
      if u.data.present?
        if u.data.has_key?("role") == false
          data_hash = u.data
          data_hash[:role] = "Noob"
          u.data = data_hash
          u.data_will_change!
          u.save!
        end
      else
        u.data = { role: "Noob" }
        u.save!
      end
    end
    render json: "test3"
  end

  def sign_in
     if params[:email].present? and params[:password].present?
       email = params[:email]
       password = params[:password]
       # Check for user authentication
       user = Devuser.find_by_email(email)
       error_notice = "WE COULDN'T FIND AN ACCOUNT WITH THAT USER ID/PASSWORD COMBINATION. PLEASE TRY AGAIN"

       if user.present?
         unless user.valid_password?(password)
           # Redirects back to index if password is wrong
          render json:  { error: error_notice }

         else
           if user.verified == true
             dev_user_id = user.id
             applications = user.hive_applications
             app_key = nil
             user_id=nil
             auth_token = nil
             applications.each do |application|
               app_key = application.api_key if application.app_name.casecmp("juice app")
               user = User.find_by_username("JuiceAppBoard")
               if user.present?
                  user_id = user.id
                  auth_token = user.authentication_token
               end
             end
             render json: {user_id: dev_user_id, app_key: app_key, board_id: user_id, auth_token: auth_token}
           else
             #if user hasn't verified account.
             render json:{ error: error_notice }
           end
         end
       else
         # if user enters the wrong email address.
         render json:{ error: error_notice }
       end

     end
  end

  def test4
    p User::BOT
    render json: SecureRandom.urlsafe_base64
  end

end
