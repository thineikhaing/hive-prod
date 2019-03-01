class Api::UsersController < ApplicationController

  # force_ssl if: :ssl_configured?
  respond_to :json
  skip_before_action :verify_authenticity_token

  # def ssl_configured?
  #   !Rails.env.development?
  # end

  def get_user
    if params[:auth_token].present? && params[:user_id].present?
      user =User.find_by_id(params[:id])
      render json: {status:200, message: "",user: user}
    end
  end

  def get_trip_list
    trips = Trip.where(user_id: current_user.id)
    # if trips.count > 11
    #   ids = trips.limit(10).order('id DESC').pluck(:id)
    #   trips.where('id NOT IN (?)', ids).destroy_all
    # end

    params[:num_trips].present? ? num_trips = params[:num_trips].to_i : num_trips=0
    params[:trip_id].present? ? trip_id= params[:trip_id].to_i : trip_id=0
    params[:get_all].present? ? get_all= params[:get_all].to_i : get_all = 0

    if get_all == 1
      trips = trips.order("id DESC")
    else
      if num_trips == 0 && trip_id ==0
        trips =  trips.order("id DESC").limit(10)
      elsif num_trips > 0 && trip_id ==0
        trips =  trips.order("id DESC").limit(num_trips)
      elsif num_trips == 0 && trip_id > 0
        trips =  trips.where("id < ?", trip_id).order("id DESC").limit(10)
      elsif num_trips > 0 && trip_id > 0
        trips =  trips.where("id < ?", trip_id).order("id DESC").limit(num_trips)
      end
    end


    trip_detail =  []
    trip_list = []
    trips.each do |trip|
      detail = trip.data["route_detail"]
      tt_detail = eval(detail) unless detail.nil?
      trip_detail.push(tt_detail)
      p "trip.native_legs"
      # p JSON.parse(trip.native_legs["data"])
      native_data = trip.native_legs["data"] unless trip.native_legs.nil?

      begin
        native_data = JSON.parse(native_data)
      rescue
         puts "Rescued: JSON parsing"
      end


      trip_list.push(
        id: trip.id,
        user_id: trip.user_id,
        depature_name: trip.depature_name,
        arrival_name: trip.arrival_name,
        start_addr: trip.start_addr,
        end_addr: trip.end_addr,
        transit_mode: trip.transit_mode,
        depature_time: trip.depature_time,
        arrival_time: trip.arrival_time,
        duration: trip.duration,
        distance: trip.distance,
        fare: trip.fare,
        currency: trip.currency,
        source: trip.data["source"],
        country: trip.data["country"],
        depart_lat: trip.depart.latitude,
        depart_lng: trip.depart.longitude,
        arrive_lat: trip.arrive.latitude,
        arrive_lng: trip.arrive.longitude,
        legs:tt_detail,
        native_legs:native_data)
    end


    render json: {status:200, message: "User Trip List",trip_list:trip_list}
  end

  def get_user_avatar
    if params[:username]

      user = User.find(params[:user_id])
      pp = user.avatar_url

      if pp.present?
        avatar = pp
        render json: { avatar_url: avatar , status: 's3 pic'}

      elsif params[:username] == "FavrBot"
        avatar = "assets/Avatars/Chat-Avatar-Admin.png"
        render json: { local_avatar: avatar , status: 'local pic'}

      else

        avatar = Topic.get_avatar(params[:username])
        render json: { local_avatar: avatar , status: 'local pic'}

      end

    else params[:profile_picture]

      user = User.find(params[:userid])
      if user.present?
        user.avatar_url  = params[:profile_picture]
        user.save
        render json: { status: "save user profile picture" }
      end
    end
  end

  def create_anonymous_user
    if params[:device_id].present?
      app_key = params[:app_key] if params[:app_key].present?
      app_key = params[:api_key] if params[:api_key].present?

      hiveapp = HiveApplication.find_by_api_key(app_key)
      push_token = params[:push_token]

      if User.find_by_device_id(params[:device_id]).present?
        user = User.where(device_id: params[:device_id]).take
        message = "DeviceId already existed in system"
      else
        user = User.create!(device_id: params[:device_id], password: Devise.friendly_token,token_expiry_date: Date.today + 6.months)
        app_data = Hash.new
        app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key
        user.app_data = app_data
        user.save!
        message = "Created user successfully"
      end
      if user.present?
        if push_token.present?
          p "check before create "
          p chk_duplicate = UserPushToken.find_by(push_token: push_token)
          if chk_duplicate.present?
            chk_duplicate.update(user_id: user.id,notify: true)
          else
            User.create_endpoint(params[:device_type], push_token ,user.id)
          end

        end
        user_apps = UserHiveapp.find_by(user_id: user.id,hive_application_id: hiveapp.id)
        UserHiveapp.create(user_id: user.id,hive_application_id: hiveapp.id) unless user_apps.present?
        render json: { status:200,
          message:message,
          :user => user,
          :success => 20 ,
          local_avatar:  Topic.get_avatar(user.username),
          daily_point: user.daily_points}, status: 200
      end
    else
      render json: { status:201, message: "Invalid application key", error_msg: "Invalid application key" } , status: 400
    end
  end

  def register_push_token
    if current_user.present?
      if params[:device_token].present?
        p "register token"
        chk_duplicate = UserPushToken.find_by(user_id: current_user.id, push_token: params[:device_token])
        if chk_duplicate.present?
          p "duplicate exit ***"
          tokens = UserPushToken.where(endpoint_arn: chk_duplicate.endpoint_arn)
          user_token = UserPushToken.find_by(user_id: current_user.id, endpoint_arn: chk_duplicate.endpoint_arn)
          tokens.where.not(id: user_token.id).delete_all
          render json: { status: 200,user_id: current_user.id,token: user_token, message: "Register token!"}
        else
          p "create new ***"
          message = User.create_endpoint(params[:device_type], params[:device_token],params[:user_id])
          user_tokens = UserPushToken.where(user_id: params[:user_id], push_token: params[:device_token])
          user_tokens.first.delete if user_tokens.count > 1

          render json: { status: 200, message: message}
        end

      else
        render json: { status: 201, message: "Need device token parameter for SNS register"}
      end
    else
      render json: { status: 201, message: "Need user id and auth token to access api"}
    end
  end

  def sign_up

    if params[:auth_token].present?
      user = User.find_by_authentication_token(params[:auth_token])
      if current_user.present?

        checkEmail = User.find_by_email(params[:email])
        var = [ ]

        if checkEmail.nil?
          if params[:username].present?
            checkUsername = User.search_data(params[:username])
            var.push(33) if Obscenity.profane?(params["username"]) == true
            username = params[:username]
            checkName = User.where("LOWER(username)  =?", username.downcase).take
            if checkName.present?
              var.push(33) #if checkUsername.present?
              message = "The username has already been taken"
            end
          end

          if var.empty?
            user.username = params[:username]
            user.email = params[:email]
            user.password = params[:password]
            user.password_confirmation = params[:password]
            user.token_expiry_date= Date.today + 6.months
            user.save!

            if params[:app_key]
              hiveapp = HiveApplication.find_by_api_key(params[:app_key])
              app_data = Hash.new
              app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key
              user.app_data = Hash.new if user.app_data.nil?
              user.app_data = user.app_data.merge(app_data)
              user.save!
              user_apps = UserHiveapp.find_by(user_id: user.id,hive_application_id: hiveapp.id)
              UserHiveapp.create(user_id: user.id,hive_application_id: hiveapp.id) unless user_apps.present?
            end

            userFav = UserFavLocation.where(user_id: user.id).order('id desc')
            friend_lists = UserFriendList.where(user_id: user.id)

            previous_token = UserPushToken.find_by_user_id(current_user.id)
            if previous_token.present?
              previous_token.update(user_id: user.id)
              sns_client = Aws::SNS::Client.new
              resp = sns_client.set_endpoint_attributes({
                      endpoint_arn: previous_token.endpoint_arn, # required
                      attributes: { # required
                        "CustomUserData" => user.id.to_s,
                      },
                    })
            end

            render json: {status:200,
              message: "User sign up successfully",
              user: user,
              userfavlocation: userFav,
              friend_list: friend_lists,
              name: user.username, id: user.id,
              local_avatar: Topic.get_avatar(user.username) ,
              success: 20 }, status: 200

          else
            render json: {status: 201, message: message, :error => var}, status: 400
          end
        else
          var.push(11)
          render json: { status:201, message: "Email already exist!", :error => var}, status: 400 # Email already exist
        end

      else
        render json: { error_msg: "Invalid user id/ authentication token" }, status: 400
      end

    else

      render json: { error_msg: "Param authentication token must be presented" }, status: 400
    end
  end

  def sign_in
    params[:bt_mac_address].present? ? bt_mac_address = params[:bt_mac_address] : bt_mac_address = ""
    if params[:email].present? and params[:password].present?
      var = [ ]
      user = User.find_by_email(params[:email])
      if user.present?
        if user.valid_password?(params[:password])
          userFav = UserFavLocation.where(user_id: user.id).order('id desc')

          if current_user.present?
            p "previous user"
            p previous_user = User.find(current_user.id)
            previous_token = UserPushToken.find_by_user_id(current_user.id)
            if previous_token.present?
              p previous_token.endpoint_arn
              p "update push token user id in hive and aws sns"
              previous_token.update(user_id: user.id)
              sns_client = Aws::SNS::Client.new
              resp = sns_client.set_endpoint_attributes({
                endpoint_arn: previous_token.endpoint_arn, # required
                attributes: { # required
                  "CustomUserData" => user.id.to_s,
                },
              })
            end
          end

          render json: {status:200, message: "sign in successfully",
            user: user,
            userfavlocation: userFav,
            local_avatar: Topic.get_avatar(user.username),
            success: 20 }, status: 200
        else
          var.push(22)
          render json: {status:201, message: "Wrong Password. Please try again.", error: var}, status: 400 # User password wrong
        end


      else
        var.push(21)
        render json: { status:201, message:"No account found with those details. Reset your password or sign up for a new account.",:error => var}, status: 400 # User email doesn't exist
      end

    elsif params[:app_name]
      user = User.find_by_device_id(params[:device_id])

      if user.present?
        result = Hash.new
        result[:device_id] = params[:device_token]
        user.data = result
        user.save!
      else
        user = User.new(device_id: params[:device_id], password: Devise.friendly_token)
        user.save
      end
      avatar = Topic.get_avatar(user.username)
      render json: { :user => user, :success => 20 , avatar: avatar, daily_point: user.daily_points}, status: 200
    else
      render json: {error_msg: "Params email and password must be presented"} , status: 400
    end
  end

  def facebook_login
    if params[:fb_id].present? and current_user.present?
      var = [ ]
      user = User.find (current_user.id)
      # fb_account = UserAccount.find_all_by_account_type_and_linked_account_id("facebook",params[:fb_id])

      fb_account = UserAccount.find_by_linked_account_id(params[:fb_id])

      if user.present?
        if fb_account.present?
          #user_accounts = UserAccount.where(:user_id => user.id)
          #render json: { :user => user,  :user_accounts => user_accounts, :success => 40 }, status: 200
          user = User.find (fb_account.user_id)
          user_accounts = UserAccount.where(:user_id => user.id)

          name = user.username
          id = user.id
          avatar = Topic.get_avatar(user.username)

          userFav = UserFavLocation.where(user_id: user.id).order('id desc')

          friend_lists = UserFriendList.where(user_id: user.id)

          activeUsersArray = [ ]
          friend_lists.each do |data|
            activeuser = User.find(data.friend_id)
            usersArray= {id: user.id, username: activeuser.username,last_known_latitude:activeuser.last_known_latitude,last_known_longitude:activeuser.last_known_longitude,avatar_url:activeuser.avatar_url,local_avatar: Topic.get_avatar(activeuser.username)}
            activeUsersArray.push(usersArray)
          end

          # render json: { :user => user,  :fb_exists => true, :user_accounts => user_accounts, :success => 40 }, status: 200
          render json: { :user => user,  :fb_exists => true, user_accounts: user_accounts,userfavlocation: userFav,friend_list: activeUsersArray, :name => name, :id => id, local_avatar: avatar , :success => 40 }, status: 200

          # if fb_account.user_id == user.id
          #   user_accounts = UserAccount.where(:user_id => user.id)
          #   render json: { :user => user,  :fb_exists => true, :user_accounts => user_accounts, :success => 40 }, status: 200
          # else
          #   var.push (41)
          #   render json: { :error => var }, status: 400
          # end
        else
          user.email = params[:email]
          user.save
          account = UserAccount.new
          new_account = UserAccount.create(user_id: user.id,account_type: "facebook", priority: 0, linked_account_id: params[:fb_id])
          render json: { :user => user,  :fb_exists => true,:user_accounts => new_account, :success => 40 }, status: 200
        end
      else
        render json:{ error_msg: "Invalid user id/ authentication token"}, status: 400
      end
    else
      render json:{ error_msg: "Param facebook id must be presented" } , status: 400
    end
  end

  def get_reset_password_token
    user = User.find_by_email(params[:email])
    if user.present?
      user.reset_password_sent_at = Time.zone.now
      user.reset_password_token =  SecureRandom.urlsafe_base64
      user.save!
      render json:{status:"OK",username: user.username,token: user.reset_password_token}, status: 200
    else
      render json:{status:"No user"}
    end

  end

  def forget_password
    # Sends email for user to change PASSWORD
    if params[:email].present?
      user = User.find_by_email(params[:email])
      if user.present?
        user.reset_password_sent_at = Time.zone.now
        p user.reset_password_token =  [*('A'..'Z'),*('0'..'9')].shuffle[0,6].join
        user.save!
        user.delay.send_password_reset_to_app
        render json:{ status:200, message: "Email sent with password reset instructions.",token: user.reset_password_token}, status: 200
      else
        render json:{ status: 201,message: "There is no user with this email."}, status: 400
      end
    end
  end

  def update_password
    # Updates PASSWORD
    @user = User.find_by_reset_password_token(params[:token])

    if @user.present?
      p "password status"
      p status =  @user.valid_password?(params[:password])

      if @user.reset_password_sent_at < 7.days.ago
        render json:{ status: 400, message: "Password reset has expired."}, status: 400
      else
        @user.password = params[:password]
        @user.password_confirmation = params[:password_confirmation]
        @user.save

        render json:{ status:200, message: "Password has been reset!", user: @user,local_avatar:Topic.get_avatar(@user.username)}, status: 200
      end

    else
      render  json:{status: 400, message: "token invalid"}, status: 400  #err in saving password, show on reset_password page
    end

  end

  def edit_profile
    if current_user.present?
      user = User.find_by_id(current_user.id)
      var = [ ]
      message = ""

      if params[:email].present?
        checkEmail = User.find_by_email(params[:email])
        if checkEmail != nil
          var.push(31)
          message = "Email already exit."
        end
      end

      if params[:password].present?
        p params[:passowrd]
        if !user.valid_password?(params[:password])
          var.push(32)
          message = "Your old password doesn't match!"
        end
      end

      # if params[:password].present?
      #   p user.email
      #   p user.password
      #   p params[:password]
      #   if user.password != params[:password]
      #     var.push(32)
      #     message = "Password mismatched"
      #   end
      # end

      if params[:username].present?
        checkUsername = User.search_data(params[:username])
        username = params[:username]
        checkName = User.where("LOWER(username)  =?", username.downcase).take
        if checkName.present?
          var.push(33) #if checkUsername.present?
          message = "The username has already been taken."
        end
      end

      if var.empty?
        if params[:username].present?
          user.username = params[:username]
        end

        if params[:email].present?
          user.email = params[:email]
        end

        if params[:password].present?
          user.password = params[:update_password]
          user.password_confirmation = params[:update_password]
        end

        if params[:avatar_url].present?
          if params[:avatar_url].to_s == "null"
          # if !current_user.avatar_url.url.nil?
            if Rails.env.development?
              bucket_name = AWS_Bucket::Avatar_D
            elsif Rails.env.staging?
              bucket_name = AWS_Bucket::Avatar_S
            else
              bucket_name = AWS_Bucket::Avatar_P
            end
            Post.delete_S3_file(bucket_name, user.avatar_url.current_path,Post::IMAGE)
            user.remove_avatar_url!
          else
            user.avatar_url = params[:avatar_url]
          end

          # if params[:avatar_url].to_s == "null"
          # else
          # end
        end

        user.save!
        render json: { status: 200, message: "Edit Success",:user => user, local_avatar: Topic.get_avatar(user.username), :success => 30 }, status: 200
      else
        render json: {status: 201, message: message, :error => var}, status: 400
      end
    end
  end

  def facebook_friends
    fb_friends_array = [ ]
    fbIDS_array = [ ]

    if params[:fb_id].present?
      fbIDS_array = params[:fb_id].split(",")

      fbIDS_array.each do |fb|
        account = UserAccount.find_by(account_type: "facebook",linked_account_id: fb)
        if account.present?
          data = { fb_id: fb, user_id: account.user_id }
          fb_friends_array.push(data)
        end
      end

      render json: { users: fb_friends_array }
    else
      render json: { error_msg: "facebook id must be presented" }, status: 400
    end
  end

  def check_in
    # Authentication method that checks against database (taken from Devise)
    # We are not using the before_action with :authenticate_user! here because
    # We want to handle the error ourselves, and not let Devise display a sign in box
    warden.authenticate(:scope => :user, :auth_token => params[:auth_token])
    usersArray = [ ]
    activeUsersArray = [ ]

    if current_user.present? && params[:latitude].present? && params[:longitude].present?
      hiveapp = HiveApplication.find_by_api_key(params[:app_key])

      current_user.update(last_known_latitude: params[:latitude], last_known_longitude: params[:longitude])
      user = User.find(current_user.id)
      if params[:peersition].present?
          if params[:peersition] == "0"
            user.check_in_time = Time.now - 20.minutes
          else
            user.check_in_time = Time.now
          end
      else
        user.check_in_time = Time.now
      end
      user.save!

      # user.update(last_known_latitude: params[:latitude],last_known_longitude: params[:longitude])

      params[:radius].present? ? radius = params[:radius].to_i : radius = 1

      Userpreviouslocation.create(latitude: params[:latitude], longitude: params[:longitude],
        radius: radius, user_id: current_user.id) if params[:save] == "true"

      users = User.nearest(params[:latitude], params[:longitude], radius)

      if params[:app_key].present?

        users = users.where("app_data ->'app_id#{hiveapp.id}' = '#{hiveapp.api_key}'")

        if Rails.env.development?
          carmmunicate_key = Carmmunicate_key::Development_Key
        elsif Rails.env.staging?
          carmmunicate_key = Carmmunicate_key::Staging_Key
        else
          carmmunicate_key = Carmmunicate_key::Production_Key
        end

        if hiveapp.present?
          if hiveapp.api_key == carmmunicate_key
            time_allowance = Time.now - 20.seconds.ago
            if params[:data].present?
              data = getHashValuefromString(params[:data])
              data["speed"].present? ? speed = data["speed"]  : speed = "-1"
              data ["direction"].present? ? direction = data["direction"]  : direction= "-1"
              data["activity"].present? ? activity = data["activity"] : activity=""
              data["heartrate"].present? ? heartrate = data["heartrate"] : heartrate=""
              user.update_user_peerdrivedata(speed,direction,activity,heartrate)
              CarActionLog.create(user_id:  user.id,latitude: params[:latitude], longitude: params[:longitude], speed: speed, direction: direction,activity: activity, heartrate: heartrate)
            end
          else
            time_allowance = Time.now - 10.minutes.ago
          end

          users.each do |u|
            if u.check_in_time.present?
              time_difference = Time.now - u.check_in_time
              unless time_difference.to_i > time_allowance.to_i
                unless u.id == current_user.id
                  user = User.find(u.id)
                  avatar = Topic.get_avatar(user.username)
                  avatar_url = u.avatar_url.url
                  if avatar_url.nil?
                    avatar_url = ""
                  end
                  active_users = { id: u.id, username: u.username, avatar_url: avatar_url,
                      local_avatar: avatar, last_known_latitude: u.last_known_latitude,
                      last_known_longitude: u.last_known_longitude , data: u.data,
                      updated_at: u.updated_at}
                  activeUsersArray.push(active_users)
                end

              end
            end
          end
          render json: { status:200, message: "Check in OK.", users: activeUsersArray}
        else
          render json: { status:201, message: "Invalid application key",error_msg: "Invalid application key" }, status:400
          return
        end
      else
        # time_allowance = Time.now - 10.minutes.ago
        render json: { status:201, message: "Param Application key must be presented", error_msg: "Param Application key must be presented"}, status: 400
      end
    else
      render json: { status:201, message: "Param user id, authentication token, latitude and longitude must be presented", error_msg: "Param user id, authentication token, latitude and longitude must be presented"}, status: 400
    end
  end


  def create_car_action_logs(user_id, lat, lng, speed, direction, activity, heartrate)
    old_log = CarActionLog.last
    if old_log.present?
      time_diff_hr = (Time.parse(DateTime.now.to_s) - Time.parse(old_log.created_at.to_s))/3600
      time_diff_min = (time_diff_hr * 3600) / 60
      if (time_diff_min >= 0.5)
        new_log = CarActionLog.create(user_id:  user_id,latitude: lat, longitude: lng, speed: speed, direction: direction,activity: activity, heartrate: heartrate)
      end

    else
      new_log = CarActionLog.create(user_id:  user_id,latitude: lat, longitude: lng, speed: speed, direction: direction,activity: activity, heartrate: heartrate)
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
      render json:{ error_msg: "Invalid user id / authentication token"} , status: 400
    end
  end

  def flare_mode
    if current_user.present? and params[:flareMode].present?
      current_user.update_attribute(:flareMode , params[:flareMode])
      render json: { status: true }
    else
      render json: { error_msg: "Params user id, authentication token and flareMode must be presented" } , status: 400
    end
  end

  def favourite_user
    if params[:fav_user_id].present? and params[:choice].present? and current_user.present?
      current_user.favourite_user(current_user, params[:user_id], params[:choice])

      render json: { status: true }
    else
      render json: { error_msg: "Params favourite user id, user id, authentication token and choice must be presented" }, status: 400
    end
  end

  def block_user
    if params[:block_user_id].present? and params[:choice].present? and current_user.present?
      user = User.find(current_user.id)
      user.block_user(current_user, params[:block_user_id], params[:choice])
      user.reload

      render json: { status: true }
    else
      render json: { error_msg: "Params user id to block, current user id, authentication token and choice must be presented" } , status: 400
    end
  end

  def user_action_logs

    users = User.all
    blockedArray = [ ]
    favArray = [ ]
    favTopicArray = [ ]
    likedTopicArray = [ ]
    likedPostArray = [ ]
    usersArray = [ ]

    count = 1
    totalUsers = users.count


    if current_user.present?
      checkBlockedArray = ActionLog.where(type_name: "user", action_type: "block", action_user_id: current_user.id)
      checkFavouriteArray = ActionLog.where(type_name: "user", action_type: "favourite", action_user_id: current_user.id)
      checkFavouriteTopicArray = ActionLog.where(type_name: "topic", action_type: "favourite", action_user_id: current_user.id)
      checkLikedTopicArray = ActionLog.where(type_name: "topic", action_type: "like", action_user_id: current_user.id)
      checkLikedPostArray = ActionLog.where(type_name: "post", action_type: "liked", action_user_id: current_user.id)

      users.each do |u|
        data = { user_id: u.id, username: u.username, points: u.points}
        usersArray.push(data)
      end
      usersArray.sort! { |a, b| a[:points] <=> b[:points] }
      usersArray = usersArray.reverse

      usersArray.each do |ua|
        ua.merge!(rank: count)
        count = count + 1
      end

      user = usersArray.select { |s| s[:user_id] == current_user.id }

      checkBlockedArray.each do |cba|
        blockedArray.push( { user_id: cba.type_id, username: User.find(cba.type_id).username } )
      end

      checkFavouriteArray.each do |cfa|
        favArray.push( { user_id: cfa.type_id, username: User.find(cfa.type_id).username } )
      end

      checkFavouriteTopicArray.each do |cfta|
        favTopicArray.push(cfta.type_id)
      end

      checkLikedTopicArray.each do |clta|
        likedTopicArray.push(clta.type_id)
      end

      checkLikedPostArray.each do |clpa|
        likedPostArray.push(clpa.type_id)
      end

      data = {
          id: current_user.id,
          username: current_user.username,
          point: current_user.points,
          favourite_topics: favTopicArray,
          liked_posts: likedPostArray,
          liked_topics: likedTopicArray,
          block_users: blockedArray,
          favourite_users: favArray,
          rank: user.first[:rank],
          total_users: totalUsers
      }

      render json: { user: data }
    else
      render json: { error_msg: "Invalid user id/ authentication token"}, status: 400
    end
  end

  def status
    users = User.all
    blockedArray = [ ]
    favArray = [ ]
    favTopicArray = [ ]
    likedTopicArray = [ ]
    likedPostArray = [ ]
    usersArray = [ ]

    count = 1
    totalUsers = users.count

    checkBlockedArray = Actionlog.where(type_name: "user", type_action: "block", action_user_id: current_user.id)
    checkFavouriteArray = Actionlog.where(type_name: "user", type_action: "favourite", action_user_id: current_user.id)
    checkFavouriteTopicArray = Actionlog.where(type_name: "topic", type_action: "favourite", action_user_id: current_user.id)
    checkLikedTopicArray = Actionlog.where(type_name: "topic", type_action: "like", action_user_id: current_user.id)
    checkLikedPostArray = Actionlog.where(type_name: "post", type_action: "liked", action_user_id: current_user.id)

    users.each do |u|
      data = { user_id: u.id, username: u.username, points: u.points }
      usersArray.push(data)
    end

    usersArray.sort! { |a, b| a[:points] <=> b[:points] }
    usersArray = usersArray.reverse

    usersArray.each do |ua|
      ua.merge!(rank: count)
      count = count + 1
    end

    user = usersArray.select { |s| s[:user_id] == current_user.id }

    checkBlockedArray.each do |cba|
      blockedArray.push( { user_id: cba.type_id, username: User.find(cba.type_id).username } )
    end

    checkFavouriteArray.each do |cfa|
      favArray.push( { user_id: cfa.type_id, username: User.find(cfa.type_id).username } )
    end

    checkFavouriteTopicArray.each do |cfta|
      favTopicArray.push(cfta.type_id)
    end

    checkLikedTopicArray.each do |clta|
      likedTopicArray.push(clta.type_id)
    end

    checkLikedPostArray.each do |clpa|
      likedPostArray.push(clpa.type_id)
    end

    data = {
        id: current_user.id,
        username: current_user.username,
        points: current_user.points,
        favourite_topics: favTopicArray,
        liked_posts: likedPostArray,
        liked_topics: likedTopicArray,
        block_users: blockedArray,
        favourite_users: favArray,
        rank: user.first[:rank],
        total_users: totalUsers
    }

    render json: { user: data }
  end

  def regenerate_username
    render json: { username: User.generate_new_username }
  end

  def update_carmmunicate_user
    if current_user.present? and params[:app_key].present?
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveapplication.present?
        user = User.find(current_user.id)
        #covert the params data to hash
        data = getHashValuefromString(params[:data]) if params[:data].present?

        #get predefined addtional columns from table and match with the params value
        appAdditionalField = AppAdditionalField.where(:app_id => hiveapplication.id, :table_name => "User")
        result = Hash.new
        if appAdditionalField.present?
          defined_Fields = Hash.new
          appAdditionalField.each do |field|
            if field.additional_column_name == "speed" or   field.additional_column_name == "direction" #default value of speed and direction is -1
              defined_Fields[field.additional_column_name] = "-1"
            else
              defined_Fields[field.additional_column_name] = ""
            end
          end
          #get all extra columns that define in app setting against with the params data
          if data.present?
            data = defined_Fields.deep_merge(data)
            defined_Fields.keys.each do |key|
              result.merge!(data.extract! (key))
            end
          else
            result = defined_Fields
          end
        end
        result = nil unless result.present?

        data_hash = {}
        user.data = result
        user.save!
        render json: { user: user }
      else
        render json: { error_msg: "Invalid application key" }, status: 400
      end
    else
      render json: { error_msg: "Param user id, authentication token and application key must be presented" }, status: 400
    end
  end

  def create_incident_history
    host_id = params[:host_id]
    peer_id = params[:peer_id]
    host_data = getHashValuefromString(params[:host_data]) if params[:host_data].present?
    peer_data = getHashValuefromString(params[:peer_data]) if params[:peer_data].present?

    defined_Fields = Hash.new

    appField = AppAdditionalField.where( :table_name => "IncidentHistory")
    appField.each do |field|
      defined_Fields[field.additional_column_name] = nil
    end
     p defined_Fields
     p host_data
      p host_data["heartrate"]
      p host_data["activity"]
      p host_data["activity"]
    if host_data.present?
      host_data = defined_Fields.deep_merge(host_data)
      hostresult = Hash.new
      defined_Fields.keys.each do |key|
        hostresult.merge!(host_data.extract! (key))
      end
    else
      hostresult = defined_Fields
    end


    if peer_data.present?
      peer_data = defined_Fields.deep_merge(peer_data)
      peerresult = Hash.new
      defined_Fields.keys.each do |key|
        peerresult.merge!(peer_data.extract! (key))
      end
    else
      peerresult = defined_Fields
    end

      old_log = IncidentHistory.last
      if old_log.present?
        old_host = old_log.host_id
        old_peer = old_log.peer_id

        p "old host id"
        p old_host
        p "old peer id"
        p old_peer

        p "new host & peer"
        p host_id
        p peer_id

        time_diff_hr = (Time.parse(DateTime.now.to_s) - Time.parse(old_log.created_at.to_s))/3600
        p time_diff_min = (time_diff_hr * 3600) / 60

        if (time_diff_min < 30)
          p "time is less than 30"
          if (old_host.to_i != peer_id.to_i && old_host.to_s != host_id.to_i)
            p "not equal record within 30s"
            incident_hostory = IncidentHistory.create(host_id: host_id,
                                                      peer_id: peer_id,
                                                      host_data: hostresult,
                                                      peer_data: peerresult)
          end

        else
          p "very new record"
          incident_hostory = IncidentHistory.create(host_id: host_id,
                                                    peer_id: peer_id,
                                                    host_data: hostresult,
                                                    peer_data: peerresult)

        end


      else
        "first record"
        incident_hostory = IncidentHistory.create(host_id: host_id,
                                                  peer_id: peer_id,
                                                  host_data: hostresult,
                                                  peer_data: peerresult)
      end
      render json: { status: "ok"}

  end

  def check_hive_user
    email = params[:email]
    user = User.find_by_email(email)
    if user.present?

      render :json => { status: "ok", user: user}.to_json   ,:callback => params[:callback]

    else
      render json: {status: "no"}.to_json ,:callback => params[:callback]
    end

    if params[:hive_id]
      user = User.find(params[:hive_id])
      if user.present?
        user.socal_id = params[:socal_id]
        user.save!
      end

    end

  end

  def save_user_fav_location
    place_id = nil
    #check the place_id presents
    if current_user.present?

      place = Place.new
      params[:name].present? ? name = params[:name] : name = nil
      params[:latitude].present? ? latitude = params[:latitude] : latitude = nil
      params[:longitude].present? ? longitude = params[:longitude] : longitude = nil
      params[:address].present? ? address = params[:address] : address = nil
      params[:source].present? ? source = params[:source] : source = nil
      params[:source_id].present? ? source_id = params[:source_id] : source_id = nil
      params[:place_id].present? ? place_id = params[:place_id] : place_id = nil
      params[:choice].present? ? choice = params[:choice] : choice = nil
      params[:img_url].present? ? img_url = params[:img_url] : img_url = nil
      params[:place_type].present? ? place_type = params[:place_type] : place_type = nil
      params[:locality].present? ? locality = params[:locality] : locality=""
      params[:country].present? ? country = params[:country] : country=""
      params[:postcode].present? ? postcode = params[:postcode] : postcode=""

      user = User.find_by_authentication_token (params[:auth_token]) if params[:auth_token].present?

      place = place.add_record(name, latitude, longitude, address, source, source_id,
                               place_id, current_user.id, current_user.authentication_token,
                               choice,"","",locality,country,postcode)
      p user.id
      p status = place[:status]
      p place_id = place[:place].id

      # pp = Place.find(place_id)
      # pp.source_id = source_id
      # pp.save!
      # p 'save soruce id'


      fav_lists = UserFavLocation.where(user_id: current_user.id).order('id desc')
      userfav = UserFavLocation.find_by(user_id: user.id , place_id: place_id)

      if userfav.nil?
        fav_place = UserFavLocation.create(user_id: current_user.id, place_id: place_id,
            place_type: params[:place_type],name: name,address: params[:address] ,img_url: img_url)

        render json:{fav_place: fav_place , userfavlocation: fav_lists,status:200, message: "Location added successfully."}

      else
        p "exiting place ::::: "
        update_place = UserFavLocation.find_by(place_id: place_id,user_id: current_user.id)
        update_place.place_type =  params[:place_type]
        update_place.save!
        fav_lists = UserFavLocation.where(user_id: current_user.id).order('id desc')
        render json:{fav_place: UserFavLocation.find_by_place_id(place_id) , userfavlocation: fav_lists , status:200 , message: "Duplicate location" }
      end

    else
      render json:{status:201, message: "user_id and auth_token params must be presented",error_msg: "user_id and auth_token params must be presented"} , status: 400
    end
  end

  def update_user_fav_location
    place_id = nil
    #check the place_id presents
    if current_user.present?

      p "update id"
      p update_id = params[:id]
      userfav = UserFavLocation.find(update_id)

      place = Place.new
      params[:name].present? ? name = params[:name] : name = nil
      params[:latitude].present? ? latitude = params[:latitude] : latitude = nil
      params[:longitude].present? ? longitude = params[:longitude] : longitude = nil
      params[:address].present? ? address = params[:address] : address = nil
      params[:source].present? ? source = params[:source] : source = nil
      params[:source_id].present? ? source_id = params[:source_id] : source_id = nil
      params[:place_id].present? ? place_id = params[:place_id] : place_id = nil
      params[:choice].present? ? choice = params[:choice] : choice = nil
      params[:img_url].present? ? img_url = params[:img_url] : img_url = nil
      params[:place_type].present? ? place_type = params[:place_type] : place_type = nil
      params[:locality].present? ? locality = params[:locality] : locality=""
      params[:country].present? ? country = params[:country] : country=""
      params[:postcode].present? ? postcode = params[:postcode] : postcode=""

      p place = place.add_record(name, latitude, longitude, address, source, source_id,
                                 place_id, current_user.id, current_user.authentication_token,
                                 choice,"",place_type,locality,country,postcode)
      p "place to be update id"
      p updated_id = place[:place].id

      p userfav = userfav.update(place_id: place[:place].id,name: name,img_url:img_url)


      if userfav.present?

        @fav_locations = UserFavLocation.where(user_id: current_user.id).order('id desc')
        render json:{ status:200, message:"Upate Location",userfavlocation: @fav_locations}

      else
        render json:{status:201, message: 'location already exit!'}
      end

    else
      render json:{status:201, message: "Params app_key must be presented" ,error_msg: "Params app_key must be presented"} , status: 400
    end

  end

  def get_user_fav_location
    if params[:app_key].present?
      @userFav = UserFavLocation.where(user_id: params[:user_id]).order('id desc')
      render json: { status: 200, message:"Favourite location list",userfavlocation: @userFav}
    else
      render json:{status:201, message: "Params app_key must be presented", error_msg: "Params app_key must be presented"} , status: 400
    end
  end

  def delete_user_fav_location
    if current_user.present?

      s3 = Aws::S3::Client.new
      if Rails.env.development?
        bucket_name = AWS_Bucket::Image_D
      elsif Rails.env.staging?
        bucket_name = AWS_Bucket::Image_S
      else
        bucket_name = AWS_Bucket::Image_P
      end

      if params[:id].present?
        loc_to_delete = UserFavLocation.find(params[:id])
        if loc_to_delete.present?


          file_name = loc_to_delete.img_url
          if file_name.present?
            resp = s3.delete_object({
              bucket: bucket_name,
              key: file_name,
            })
          end

          loc_to_delete.destroy

          fav_locations = UserFavLocation.where(user_id: params[:user_id]).order('id desc')
          render json: {status:200, message: "Delete favourite location by id.", userfavlocation: fav_locations}  , status: 200
        end
      elsif params[:ids].present?
        p "selected id to delete"
        p selected_ids = params[:ids].to_a

        for i in 0..selected_ids.count-1
          fav_id = selected_ids[i].to_i


          file_name = UserFavLocation.find(fav_id).img_url
          if file_name.present?
            resp = s3.delete_object({
              bucket: bucket_name,
              key: file_name,
            })
          end

          UserFavLocation.find(fav_id).destroy

        end

        fav_locations = UserFavLocation.where(user_id: params[:user_id]).order('id desc')
        render json: {status:200, message: "Delete favourite location by id.", userfavlocation: fav_locations}  , status: 200


      end


    else
      render json:{status:201, message: "Params auth_token and user_id must be presented and valid", error_msg: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

  def get_user_friend_list

    if current_user.present?
      friend_lists = UserFriendList.where(user_id: current_user.id)

      activeUsersArray = [ ]
      friend_lists.each do |data|
        user = User.find(data.friend_id)
        usersArray= {id: user.id, username: user.username,
          last_known_latitude:user.last_known_latitude,last_known_longitude:user.last_known_longitude,
          avatar:user.avatar_url.url,
          local_avatar: Topic.get_avatar(user.username)}
        activeUsersArray.push(usersArray)
      end
      render json: {status:200, message: "Friend list", friend_list: activeUsersArray}  , status: 200
    else
      render json:{status:201, message: "Params auth_token and user_id must be presented and valid.", error_msg: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

  def save_user_friend_list
    if current_user.present?
       friend = User.find(params[:friend_id])
       if friend.present?
         UserFriendList.create(user_id: current_user.id,friend_id: params[:friend_id])
         friend_lists = UserFriendList.where(user_id: current_user.id)
         usersArray = [ ]
         activeUsersArray = [ ]
         friend_lists.each do |data|
           p data
           user = User.find(data.friend_id)
           usersArray= {id: user.id, username: user.username,
             last_known_latitude:user.last_known_latitude,last_known_longitude:user.last_known_longitude,
             avatar:user.avatar_url.url,local_avatar: Topic.get_avatar(user.username)}
           activeUsersArray.push(usersArray)
         end
         render json: {status: 200, message: "Saved user's friend list", friend_list: activeUsersArray}  , status: 200
       else
         render json: {status: 200, message: "There is no user to saved", friend_list: activeUsersArray}  , status: 200
       end

    else
      render json:{status:201, message: "Params auth_token and user_id must be presented and valid.", error_msg: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

  def delete_user_friend_list
    if current_user.present?

      user_to_delete = UserFriendList.find_by(friend_id: params[:friend_id],user_id: current_user.id)
      if user_to_delete.present?
        user_to_delete.destroy

        friend_lists = UserFriendList.where(user_id: current_user.id)

        usersArray = [ ]
        activeUsersArray = [ ]
        friend_lists.each do |data|
          p data
          user = User.find(data.friend_id)
          usersArray= {id: user.id, username: user.username,
            last_known_latitude:user.last_known_latitude,last_known_longitude:user.last_known_longitude,
            avatar:user.avatar_url.url,local_avatar: Topic.get_avatar(user.username)}
          activeUsersArray.push(usersArray)
        end
        render json: {status:200,message: "Deleted user's friend list", friend_list: activeUsersArray}  , status: 200

      else
        render json: {status:200, message: "There is no user to delete"}  , status: 200
      end

    else
      render json:{status:201, message: "Params auth_token and user_id must be presented and valid.", error_msg: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

  def update_noti_setting
    if current_user.present?
      user_push_tokens = UserPushToken.where(push_token: params[:push_token])
      if user_push_tokens.present?
        if params[:notify] == "1"
          user_push_tokens.update_all(notify: true)
        else
          user_push_tokens.update_all(notify: false)
        end
        render json: {status:200,message: "Update user noti setting for this device."}
      else
        render json:{status: 201, message: "There is no token related to user"} , status: 400
      end
    else
      render json:{status: 201, message: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role, :points, :honor_rating, :created_at, :data, :device_id,:socal_id,:daily_points)
  end


end
