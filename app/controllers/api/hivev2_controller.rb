class Api::Hivev2Controller < ApplicationController

  def get_topic_by_latlon

    if Rails.env.development?
      @carmmunicate_key = Carmmunicate_key::Development_Key
      @favr_key = Favr_key::Development_Key
      @meal_key = Mealbox_key::Development_Key
      @socal_key = Socal_key::Development_Key
      @hive_key = Hive_key::Development_Key
      @round_key = RoundTrip_key::Development_Key

    elsif Rails.env.staging?
      @carmmunicate_key = Carmmunicate_key::Staging_Key
      @favr_key = Favr_key::Staging_Key
      @meal_key = Mealbox_key::Staging_Key
      @socal_key = Socal_key::Staging_Key
      @hive_key = Hive_key::Staging_Key
      @round_key = RoundTrip_key::Staging_Key

    else
      @carmmunicate_key = Carmmunicate_key::Production_Key
      @favr_key = Favr_key::Production_Key
      @meal_key = Mealbox_key::Production_Key
      @socal_key = Socal_key::Production_Key
      @hive_key = Hive_key::Production_Key
      @round_key = RoundTrip_key::Production_Key
    end

    if params[:api_key] == @carmmunicate_key
      p appname = "carmunicate"

    elsif params[:api_key] == @favr_key
      p appname = "favr"

    elsif params[:api_key] == @meal_key
      p appname = "meal"

    elsif params[:api_key] == @socal_key
      p appname = "socal"

    elsif params[:api_key] == @round_key
      p appname = "round"

    else
      p appname = "hive"
    end

    if !params[:param_place].nil?
      #call from markerclusterer
      @place_array = params[:param_place].split(",")
      session[:places]= @place_array
      @place_array = session[:places]
    end

    lat = params[:cur_lat]
    lng = params[:cur_long]

    place_array = [ ]
    topicsInView_array = [ ]
    lat1 =Float(lat)
    long1 =Float(lng)

    app = HiveApplication.find_by_api_key(params[:api_key])

    #Retrieve the sticky topic
    #stickyTopic = Topic.where(:special_type => "3", :topic_type => 0)
    p "sticky topic"
    p stickyTopic = Topic.where("special_type =? and topic_type in (?) and hiveapplication_id =?", "3", [0,1,2,3],app.id)

    if @place_array.present?
      place_array = @place_array
      places= Place.where(:id=>@place_array)
      for pl in places
        topics = nil
        topics =  pl.topics.where("special_type<>? and hiveapplication_id =? ","3", app.id) if pl.topics.present?
        unless topics.nil?
          for topic in topics
            topicsInView_array.push(topic)
          end
        end
      end
      p "topicsInView_array"
      p listOfTopics = topicsInView_array
      listOfTopics.sort! { |a,b| a.created_at <=> b.created_at }
      listOfTopics.reverse!

      @topics_list= stickyTopic
      @topics_list+= listOfTopics

      p "total topic"
      p @topics_list.count


      usersArray = [ ]
      activeUsersArray = [ ]

      time_allowance = Time.now - 10.minutes.ago
      users = User.nearest(lat1, long1, 1)

      p "user by app_key"
      p users = users.where("app_data ->'app_id#{app.id}' = '#{app.api_key}'")


      users.each do |u|
        if u.check_in_time.present?
          time_difference = Time.now - u.check_in_time
          unless time_difference.to_i > time_allowance.to_i
            usersArray.push(u)
          end
        end
      end

      users.each do |ua|

        user = User.find(ua.id)
        active_users = { id: ua.id, username: ua.username,
                         last_known_latitude: ua.last_known_latitude,
                         last_known_longitude: ua.last_known_longitude ,
                         app_data: ua.app_data,
                         data: ua.data, updated_at: ua.updated_at}
        activeUsersArray.push(active_users)

      end

      username = ''
      avatar = ''
      pop_topic = ''
      postcount = 0
      if users.count > 0
        p "username and avatar"
        p username = users.first.username
        p avatar = Topic.get_avatar(users.first.username)
      end

      if @topics_list.count > 0
        pop_topic= @topics_list.first
        p postcount = @topics_list.first.posts.count
      end

      render json: {pop_topic: pop_topic,
                    topics_list: @topics_list,
                    topic_count: @topics_list.count,
                    post_count: postcount,
                    activeUsersArray: activeUsersArray,
                    usercount: users.count,
                    activename: username,
                    avatar: avatar,
                    appname: appname}
    else

      render json: {topicslist: "no topic list",appname: appname}
    end



  end

  def place_for_map_view
    placesMap = Place.order("created_at DESC").reload
    render json: {places: placesMap }
  end

  def get_posts_by_topicid

    if params[:topic].present?
      topic = Topic.find(params[:topic])
      lat1 =Float(cookies[:currentlat])
      long1 =Float(cookies[:currentlng])
      topicavatar = get_avatar(topic.user.username)

     posts = Post.where(topic_id: topic.id)
     post_avatar_url = Hash.new

     posts.each do |post|
       username = post.user.username
       get_avatar(username)
       post_avatar_url[post.id] = (@avatar_url)
     end

      p posts
      p posts.count

      render json: {topic: topic,posts: posts, postavatars: post_avatar_url, topicavatar: topicavatar}

    elsif params[:app_id]
      topic_avatar_url = Hash.new
      app = HiveApplication.find_by_api_key(params[:app_id])

      topics = Topic.where(hiveapplication_id: app.id)

      topics.each do |topic|
        username = topic.user.username
        get_avatar(username)
        topic_avatar_url[topic.id] = (@avatar_url)
      end

      render json: {topics: topics,posts: posts, topicavatars: topic_avatar_url}

    end
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

end