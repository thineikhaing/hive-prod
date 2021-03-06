class CarmicController < ApplicationController
  def index
    @users =User.where("data -> 'color' != ''")
    @car_action_logs = CarActionLog.order("created_at desc")
    @incidents = IncidentHistory.all.order("id desc")
    @current_incidents = IncidentHistory.where(created_at: (1.hours.ago..Time.now)).order("id desc")

    hiveapp = HiveApplication.find_by_app_name("Carmmunicate")

    @topics= Topic.where(hiveapplication_id: hiveapp.id)
    @hash = Gmaps4rails.build_markers(@users) do |user, marker|

      marker.lat user.last_known_latitude
      marker.lng user.last_known_longitude
      marker.infowindow user.data["plate_number"]

      marker.picture({
                     url: "..//assets/red_car.png#red",
                     width: 33,
                     height: 80
                 })

      marker.json({custom_marker: "<div class='marker_icon' style='background:#"+user.data["color"]+";width:33;height:80'><img src='#{"..//assets/CarMask.png"}'></div>",
                   marker_id: user.id
                  })

    end

    @latitude = params[:cur_lat]
    @longitude = params[:cur_long]

    @filter_by_time = false

    if params[:user_ids]
      @activeUsersArray = []
      p "user array"
      p user_arr = params[:user_ids]
      user_arr.each do |id|
        user = User.find(id)
        @activeUsersArray.push(user)
      end
    end

    if params[:cur_lat].present?
      @posts = nil
      @filter_by_time =  false
      get_all_topics(@latitude, @longitude)
      get_nearest_user(@latitude, @longitude)
    end

    if  params[:id].present?
      p "got topic id"
      @post_lists = params[:id]
      get_all_posts(@post_lists)
    end

    if params[:time_filter].present?

      @filter_by_time = true
      p "time filter"
      p backtime = params[:time_filter].to_i
      @topic_by_time = @topics.where(created_at: (backtime.hours.ago..Time.now)).order("id desc")
      p @incidents = IncidentHistory.where(created_at: (backtime.hours.ago..Time.now)).order("id desc")

      if not @topic_by_time.nil?
        for topic in @topic_by_time
          #getting avatar url
          @topic_by_time_avatar_url = Hash.new
          if topic.offensive < 3 and topic.special_type == 3
            @topic_by_time_avatar_url[topic.id] = "/assets/Avatars/Chat-Avatar-Admin.png"
          else
            username = topic.user.username
            get_avatar(username)
            @topic_by_time_avatar_url[topic.id] = request.url.split('?').first + @avatar_url
          end
        end
      end

      p @topic_by_time.count
    end

    if params[:current_incident]
      p "show the current incident"
      @current_incidents = IncidentHistory.where(created_at: (1.hours.ago..Time.now)).order("id desc")

    end

    if Rails.env.development?
      @url = "http://localhost:5000/api/downloaddata/retrieve_carmic_user"
      @image_url = AWS_Link::AWS_Image_D_Link
      @audio_url = AWS_Link::AWS_Audio_D_Link

    elsif Rails.env.staging?
      @url = "http://h1ve-staging.herokuapp.com/api/downloaddata/retrieve_carmic_user"
      @image_url = AWS_Link::AWS_Image_S_Link
      @audio_url = AWS_Link::AWS_Audio_S_Link
    else
      @url = "http://h1ve-production.herokuapp.com/api/downloaddata/retrieve_carmic_user"
      @image_url = AWS_Link::AWS_Image_P_Link
      @audio_url = AWS_Link::AWS_Audio_P_Link
    end

  end

  def get_nearest_user(lat, lng)
    @usersArray = []
    @activeuserRadius = []

    users = User.nearest(lat, lng, 6)
    users =users.where("data -> 'color' != ''")

    users.each do |u|
      if u.check_in_time.present?
        @usersArray.push(u)
      end
    end


    @usersArray.each do |ua|
        user = User.find(ua.id)
        @activeuserRadius.push(user)
    end

  end

  def get_all_topics(lat,lng)
    places = Place.nearest(lat,lng,5)
    if places.present?
      places_id = []
      places.each do |p|
        places_id.push p.id
      end
      # @topics_list = Topic.where(place_id:places_id, hiveapplication_id: 3).order("id desc")

      @total_topic_count = @topics_list = Topic.where(place_id:places_id, hiveapplication_id: 3).order("id desc")

      @inc_list = IncidentHistory.first
      if not @topics_list.nil?
        for topic in @topics_list
          #getting avatar url
          @topic_avatar_url = Hash.new
          if topic.offensive < 3 and topic.special_type == 3
            @topic_avatar_url[topic.id] = "/assets/Avatars/Chat-Avatar-Admin.png"
          else
            username = topic.user.username
            get_avatar(username)
            @topic_avatar_url[topic.id] = request.url.split('?').first + @avatar_url
          end
        end
      end
    end
  end

  def get_all_posts(topicid)
      p "call get all post"
      p @topic_title = Topic.find(topicid).title

      p @topic = Topic.where(id: topicid).first.reload
      p @posts = @topic.posts.includes(:user).sort #limits max 20 posts???
      @post_avatar_url = Hash.new

      @posts.each do |post|
        username = post.user.username
        get_avatar(username)
        p @post_avatar_url[post.id] = request.url.split('?').first + (@avatar_url)
      end

    @topicid = Integer(topicid)

  end

  def singup
    if params[:email] and params[:password]

      if params[:email].present?
        email = User.find_by_email(params[:email])
        if email.present?
          @err_msg = "EMAIL ALREADY EXISTS"
          @flag = false
        elsif HiveApplication.is_a_valid_email(params[:email]) == false
          @err_msg = "PLEASE ENTER A VALID EMAIL ADDRESS"
          @flag = false
        else
          @email = params[:email]
          @flag = true
        end

      end


      if params[:password].present?
        if HiveApplication.is_a_valid_password(params[:password])  == false
          @err_msg = "PASSWORDS MUST BE AT LEAST 8 CHARACTERS LONG AND INCLUDE A NUMBER"
          @flag = false
        else
          @password = params[:password]
          @flag = true
        end
      end

      if params[:confirm_password].present?

        if params[:password]!= params[:confirm_password]
          @err_msg = "PASSWORDS DO NOT MATCH"
          @flag = false
        else
          @confirm_password = params[:confirm_password]
          @flag = true
        end

      end
      p "+++++"
      p @err_msg
      p @flag
      p "+++++"
      if @err_msg.present?
        respond_to do |format|
          format.js {render inline: "location.reload();" }
        end
        flash[:error] = @err_msg
      else

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

        @user = user
        respond_to do |format|
          format.js {render inline: "location.reload();" }
        end
        flash[:success] = "Sigup New User successfully!"
      end


    else

      render json: { error_msg: "error" }, status: 400
    end
  end

  def login
    p "login"
    p params[:email]
    p params[:password]

    if params[:email].present? and params[:password].present?
      user = User.find_by_email(params[:email]).valid_password?(params[:password])
      if user.present?
        user = User.find_by_email(params[:email])
        session[:carmic_user] = user.username
        session[:carmic_user_id] = user.id
        respond_to do |format|
          format.js {render inline: "location.reload();" }
        end
      else
        respond_to do |format|
          format.js {render inline: "location.reload();" }
        end
        flash[:error] = "Username and Password mismatch!"
      end

    end
  end

  def logout
    p "logout"
    p session[:carmic_user] = nil
    p session[:carmic_user_id] = nil
    redirect_to carmic_path
  end

  def camic_reset_pwd
    params[:email]
    if params[:email].present?
      user = User.find_by_email(params[:email])
      if user.present?
        user.send_password_reset
        respond_to do |format|
          format.js {render inline: "location.reload();" }
        end
        flash[:notice] = "Email sent with password reset instructions."
      else
        respond_to do |format|
          format.js {render inline: "location.reload();" }
        end
        flash[:notice] = "Email address does not exist."
      end
    end

    p "reset password"
  end

  def get_avatar(username)
    avatar_url = nil

    #GET AVATAR URL
    #check for special case that cannot match the avatar
    avatar_url = "assets/Avatars/Chat-Avatar-Puppy.png" if(username.index("Snorkie").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Koala.png" if(username.index("Bear").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Cat").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Jaguar").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Lion").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Admin.png" if(username.index("Raydius GameBot").present?)

    urls = ["assets/Avatars/Chat-Avatar-Chipmunk.png",
            "assets/Avatars/Chat-Avatar-Puppy.png",
            "assets/Avatars/Chat-Avatar-Panda.png",
            "assets/Avatars/Chat-Avatar-Koala.png",
            "assets/Avatars/Chat-Avatar-Husky.png",
            "assets/Avatars/Chat-Avatar-Horse.png",
            "assets/Avatars/Chat-Avatar-Llama.png",
            "assets/Avatars/Chat-Avatar-Aardvark.png",
            "assets/Avatars/Chat-Avatar-Alligator.png",
            "assets/Avatars/Chat-Avatar-Beaver.png",
            "assets/Avatars/Chat-Avatar-Bluebird.png",
            "assets/Avatars/Chat-Avatar-Butterfly.png",
            "assets/Avatars/Chat-Avatar-Eagle.png",
            "assets/Avatars/Chat-Avatar-Elephant.png",
            "assets/Avatars/Chat-Avatar-Giraffe.png",
            "assets/Avatars/Chat-Avatar-Kangaroo.png",
            "assets/Avatars/Chat-Avatar-Monkey.png",
            "assets/Avatars/Chat-Avatar-Swan.png",
            "assets/Avatars/Chat-Avatar-Whale.png",
            "assets/Avatars/Chat-Avatar-Penguin.png",
            "assets/Avatars/Chat-Avatar-Duck.png",
            "assets/Avatars/Chat-Avatar-Admin.png",]
    urls.each do |url|
      if avatar_url.nil?
        url_one = [ ]
        url_one= url.split ('.png')
        url_two = [ ]
        url_two = url_one[0].split('-')
        user_names = username.split (" ")
        last_index = user_names.length
        if user_names[Integer(last_index)-1] == url_two[Integer(url_two.length)-1]
          avatar_url = url
        end
      end
    end

    #if still blank put the default avatar
    if avatar_url.nil?
      avatar_url = "assets/Avatars/Chat-Avatar.png"
    end
    @avatar_url = avatar_url
  end

  def create_post
    p "session user"
    p user = User.find(session[:carmic_user_id])
    if user.present?
      p "post merge"
      p @post = user.posts.build({ topic_id: params[:id] }.merge (params[:post]))
    end

    #last_post = Post.last
    #if last_post.content ==  params[:post][:content] && last_post.topic_id = params[:id]
    #  p "same"
    #else
    #
    #
    #end

    if @post.content.length > 255 #check for max length of content
      flash.now[:notice] =  'The max length message is 255'
      p "The max length message is 255"
    elsif @post.content.length == 0  #check content is blank?
      p "Please enter the message"
      flash.now[:notice] = 'Please enter the message'
    else
      if @post.save
        p "post is saved"
        if cookies[:currentlat].present? and cookies[:currentlng].present?
          @post.latitude = cookies[:currentlat].to_f
          @post.longitude = cookies[:currentlng].to_f
          #factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
          #factual_result = factual.table("global").geo("$circle" => {"$center" => [@post.latitude, @post.longitude], "$meters" => 1000}).first
          #@post.address = factual_result["address"]
        end
        @post.save!
        @post.broadcast
        p "finish broadcoas post"
      else
        flash.now[:notice] = 'Error in creating message'
      end
    end



    #@post.content = Rinku.auto_link(filter_profanity(@post.content))


    respond_to do |format|
      get_all_posts (params[:id])
      format.js
    end

  end

end
