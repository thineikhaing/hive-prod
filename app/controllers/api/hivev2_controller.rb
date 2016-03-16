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
      appname = "carmunicate"
    elsif params[:api_key] == @favr_key
      appname = "favr"
    elsif params[:api_key] == @meal_key
      appname = "meal"
    elsif params[:api_key] == @socal_key
      appname = "socal"
    elsif params[:api_key] == @round_key
      appname = "round"
    else
      appname = "hive"
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

      p "get all topic by lat and lng"
      @topics_list= stickyTopic
      p @topics_list+= listOfTopics

      render json: {topicslist: @topics_list, topic_count: @topics_list.count,appname: appname}
    else

      render json: {topicslist: "no topic list",appname: appname}
    end



  end

  def place_for_map_view
    @placesMap = Place.order("created_at DESC").reload

    #filtering for normal topic, image, audio and video
    @latestTopics = [ ]
    @latestTopicUser = [ ]

    @placesMap.map { |f|
      @latestTopics.push(f.topics.last)
    }

    @latestTopics.each do |topic|
      if topic.present?
        @latestTopicUser.push(topic.username)
      else
        @latestTopicUser.push("nothing")
      end
    end

    render json: {places: @placesMap,latestTopicUser: @latestTopicUser,latestTopics: @latestTopics }
  end


end