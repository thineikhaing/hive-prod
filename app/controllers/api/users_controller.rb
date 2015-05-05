class Api::UsersController < ApplicationController

  force_ssl if: :ssl_configured?

  respond_to :json

  skip_before_filter :verify_authenticity_token

  def ssl_configured?
    !Rails.env.development?
  end

  def create_anonymous_user
    if params[:device_id].present?
      if User.find_by_device_id(params[:device_id]).present?
        #device_id already existed in system
        render json: { status: false }
      else
        user = User.create!(device_id: params[:device_id], password: Devise.friendly_token)
        user.token_expiry_date= Date.today + 6.months
        user.save!
        render json: { user: user }
      end
    else
      render json: { error_msg: "Invalid application key" } , status: 400
    end
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

  def sign_up
     p  "sign up"
    if params[:auth_token].present?
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
        
      else
        render json: { error_msg: "Invalid user id/ authentication token" }, status: 400
      end
      
    elsif params[:hiveweb]
      p "sign up from hiveweb"
      p email= params[:email]
      p password = params[:password]

      user = User.new
      user.email = email
      user.password = password
      user.password_confirmation = params[:password]

      p user
      p "+++++++"
      user.save!
      p "user is saved!"

      p name = user.username
      p id = user.id
      
      render json: { name: name, id: id }, status: 200
      
    else
      
      render json: { error_msg: "Param application key must be presented" }, status: 400
    end
  end

  def check_in
    # Authentication method that checks against database (taken from Devise)
    # We are not using the before_filter with :authenticate_user! here because
    # We want to handle the error ourselves, and not let Devise display a sign in box
    warden.authenticate(:scope => :user, :auth_token => params[:auth_token])

    usersArray = [ ]
    activeUsersArray = [ ]
    p params
    if current_user.present? && params[:latitude].present? && params[:longitude].present?
      current_user.update_attributes(last_known_latitude: params[:latitude], last_known_longitude: params[:longitude])
      user = User.find(current_user.id)
      user.check_in_time = Time.now
      user.save!
      params[:radius].present? ? radius = params[:radius].to_i : radius = 1

      Userpreviouslocation.create(latitude: params[:latitude], longitude: params[:longitude], radius: radius, user_id: current_user.id) if params[:save] == "true"

      if params[:app_key].present?
        hive_application = HiveApplication.find_by_api_key(params[:app_key])
        if Rails.env.development?
          carmmunicate_key = Carmmunicate_key::Development_Key
        elsif Rails.env.staging?
          carmmunicate_key = Carmmunicate_key::Staging_Key
        else
          carmmunicate_key = Carmmunicate_key::Production_Key
        end
        if hive_application.present?
          if hive_application.api_key ==carmmunicate_key
            time_allowance = Time.now - 20.seconds.ago
            if params[:data].present?
              data = getHashValuefromString(params[:data])
              data["speed"].present? ? speed = data["speed"]  : speed = "-1"
              data ["direction"].present? ? direction = data["direction"]  : direction= "-1"
              data["activity"].present? ? activity = data["activity"] : activity=""
              data["heartrate"].present? ? heartrate = data["heartrate"] : heartrate=""
              user.update_user_peerdrivedata(speed,direction,activity,heartrate)
            end
          else
            time_allowance = Time.now - 10.minutes.ago
          end
        else
          render json: { error_msg: "Invalid application key" }, status:400
          return
        end
      else
        time_allowance = Time.now - 10.minutes.ago
      end

      users = User.nearest(params[:latitude], params[:longitude], radius)

      users.each do |u|
        if u.check_in_time.present?
          time_difference = Time.now - u.check_in_time
          unless time_difference.to_i > time_allowance.to_i
            usersArray.push(u)
          end
        end
      end

      usersArray.each do |ua|
        unless ua.id == current_user.id
          user = User.find(ua.id)
          active_users = { id: ua.id, username: ua.username, last_known_latitude: ua.last_known_latitude, last_known_longitude: ua.last_known_longitude , data: ua.data, updated_at: ua.updated_at}
          activeUsersArray.push(active_users)
        end
      end

      render json: { users: activeUsersArray }
    else
      render json: { error_msg: "Param user id, authentication token, latitude and longitude must be presented" }, status: 400
    end
  end


  def register_apn
    if params[:push_token].present?  && current_user.present?

      user_token = UserPushToken.find_by(user_id: current_user.id,push_token: params[:push_token])

      push_user = UserPushToken.create(user_id: current_user.id,push_token: params[:push_token])   unless user_token.present?

      if push_user.present?  or user_token.present?
        render json: { status: true }
      else
        render json: { error_msg: "There is no pusher token for the user" }, status: 400
      end
    elsif params[:device_token].present?
      user = User.find_by_authentication_token(params[:auth_token])
      if user.present?

        result = Hash.new
        result[:device_id] = params[:device_token]
        user.data = result
        user.save!

        render json: { status: true }
      end



    else
      render json: { error_msg: "Param user id, authentication token, pusher token must be presented" }, status: 400
    end
  end

  def verify_user_account
    if params[:auth_token].present? and params[:push_token].present?
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
        render json:{error_msg: "Invalid user id/ authentication token"}, status: 400
      end
    else
      render json:{error_msg: "Params authentication token and pusher token must be presented"} , status: 400
    end

  end

  def sign_in
    params[:bt_mac_address].present? ? bt_mac_address = params[:bt_mac_address] : bt_mac_address = ""

    if params[:email].present? and params[:password].present?
      var = [ ]
      user = User.find_by_email(params[:email])
      if user.present?
        p "present?"
        #if user.valid_password?(params[:password])
        if user.present?
          p "valid_password?"
            user_accounts = UserAccount.where(:user_id => user.id)

          p name = user.username
          p id = user.id

            render json: {:name => name, :id => id, :user => user, user_accounts: user_accounts, :success => 20 }, status: 200
        else
          var.push(22)
          render json: { :error => var }, status: 400 # User password wrong
        end


      else
        var.push(21)
        render json: { :error => var }, status: 400 # User email doesn't exist
      end

    elsif params[:device_id]
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

      p " favr user :::"
      p user


      render json: { :user => user, :success => 20 }, status: 200
    else
      render json: {error_msg: "Params email and password must be presented"} , status: 400
    end
  end

  def facebook_login
    if params[:fb_id].present? and current_user.present?
      var = [ ]
      user = User.find (current_user.id)
      fb_account = UserAccount.find_all_by_account_type_and_linked_account_id("facebook",params[:fb_id])
      if user.present?
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
      else
        render json:{ error_msg: "Invalid user id/ authentication token"}, status: 400
      end
    else
      render json:{ error_msg: "Param facebook id must be presented" } , status: 400
    end
  end

  def edit_profile
    if current_user.present?
      user = User.find_by_id(current_user.id)
      checkUsername = User.search_data(params[:username])
      checkEmail = User.find_by_email(params[:email])

      var = [ ]
      #history = Historychange.new

      if params[:username].present?
        var.push(33) if Obscenity.profane?(params["username"]) == true
        #checkName.map { |cN| var.push(33) unless var.include?(33) if cN.downcase == "cunt" or cN.downcase == "shit" or cN.downcase == "cocksucker" or cN.downcase == "piss" or cN.downcase == "tits" or cN.downcase == "fuck" or cN.downcase == "motherfucker" or cN.downcase == "suck" or cN.downcase == "cheebye" }
        var.push(32) if checkUsername.present?
      end

      if params[:email].present?
        if checkEmail != nil
          var.push(31)
        end
      end

      if var.empty?
        if params[:username].present?
          user.username = params[:username]
          #user.posts.map { |post| history.create_record("post", post.id, "update", post.topic.id) } if user.posts.present?
          #user.topics.map { |topic| history.create_record("topic", topic.id, "update", nil) } if user.topics.present?
        end

        if params[:password].present?
          user.password = params[:password]
          user.password_confirmation = params[:password]
        end

        if params[:email].present?
          user.email = params[:email]
        end

        user.save!
        render json: { :user => user, :success => 30 }, status: 200
      else
        render json: { :error => var }, status: 400
      end
    else
      render json:{ error_msg: "Param authentication token/ user id must be presented" } , status: 400
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
        data = { user_id: u.id, username: u.username, point: u.point}
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
          point: current_user.point,
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
        points: current_user.point,
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

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role, :point, :honor_rating, :created_at, :data, :device_id)
  end

  def juice_sign_in
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

end
