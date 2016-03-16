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

    stickyTopic = Topic.where("hiveapplication_id = ? and topic_type in (?)",app.id, [0,1,2,3])

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

      listOfTopics = topicsInView_array
      listOfTopics.sort! { |a,b| a.created_at <=> b.created_at }
      listOfTopics.reverse!

      @topics_list= stickyTopic
      @topics_list+= listOfTopics


      usersArray = [ ]
      activeUsersArray = [ ]

      time_allowance = Time.now - 10.minutes.ago
      users = User.nearest(lat1, long1, 1)


      if app.api_key == @carmmunicate_key
        users = users.where("app_data ->'carmic' = 'true'")
      end

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


end