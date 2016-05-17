class Api::DownloaddataController < ApplicationController

  def initial_retrieve
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      params[:radius].present? ? radius = params[:radius] : radius = nil
      if hiveApplication.present?
        p "hive application present"

        topics = Place.nearest_topics_within(params[:latitude], params[:longitude], radius, hiveApplication.id)

        if hiveApplication.id ==1 #Hive Application
          p "Hive Application"
          render json: { topics: JSON.parse(topics.to_json())}

        elsif hiveApplication.app_name == "roundtrip"

          render json: { topics: JSON.parse(topics.to_json())}

          #favr_info = []
          #meal_info = []
          #
          #user = User.find(params[:user_id])
          #useracccounts = UserAccount.where(user_id: user.id)
          #if useracccounts.count > 0
          #
          #  useracccounts.each do |acc|
          #    if acc.account_type == 'favr'
          #      #give user points and honors
          #
          #      #api/topic/favr_topics_by_user
          #
          #
          #      #app = HiveApplication.where(app_name: 'Favr')
          #      #favr_topic = Place.nearest_topics_within(params[:latitude], params[:longitude], radius, app.id)
          #      #favr_topic = favr_topic.where(user_id: user.id)
          #      #
          #      #favr_topic.each do |topic|
          #      #  favr_info.push(topic) if topic.topic_type == Topic::FAVR && topic.state != Topic::ACKNOWLEDGED && topic.state != Topic::EXPIRED && topic.state != Topic::REVOKED
          #      #end
          #
          #    elsif acc.account_type == 'mealbox'
          #      # give user fav meal list
          #
          #
          #    elsif acc.account_type == 'socal'
          #      # give the event list respect to user
          #
          #    end
          #  end
          #
          #end

        elsif hiveApplication.devuser_id==1 and hiveApplication.id!=1 and params[:choice].nil? #All Applications under Herenow account except Hive
          p "All Applications under Herenow account except Hive"
          render json: { topics: JSON.parse(topics.to_json(content: true))}

        elsif params[:choice].present? and params[:choice] == "favr"
        p "favr Application"

          favr_topics = [ ]

          topics.each do |topic|
            favr_topics.push(topic) if topic.topic_type == Topic::FAVR && topic.state != Topic::ACKNOWLEDGED && topic.state != Topic::EXPIRED && topic.state != Topic::REVOKED
          end

          p "today date"
          p Date.today
          render json: { topics: favr_topics , date: Date.today}

        else #3rd party App
          render json: { topics: JSON.parse(topics.to_json())}
        end
      else
        render json: { error_msg: "Invalid application key" }, status: 400
      end

    else
      render json: { error_msg: "Params application key must be presented" } , status: 400
    end
  end



  def retrieve_hiveapplications
    render json: {apps: JSON.parse(HiveApplication.all.to_json(:test => "true"))}
  end

  def retrieve_topics_by_app_key
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveApplication.present?
        topics = Topic.where(:hiveapplication_id => hiveApplication.id)
        if topics.present?
          render json: { topics: JSON.parse(topics.to_json())}
        else
          render json: {topics: nil}
        end
      else
        render json: { error_msg: "Invalid application key" }, status: 400
      end
    else
      render json: { error_msg: "Params application key must be presented" } , status: 400
    end
  end

  def search_database
    topic_array = [ ]
    user_array = [ ]
    place_array = [ ]
    places_data = [ ]
    users_data = [ ]
    text = params[:search]

    # Check for full word (1st priority)
    user = User.search_data(text)
    topic = Topic.search_data(text)
    post = Post.search_data(text)
    tag = Tag.search_data(text.downcase)
    place = Place.search_data(text)

    user.map { |u| user_array.push(u.id) unless user_array.include?(u.id) }
    topic.map { |to| topic_array.push(to.id) unless topic_array.include?(to.id) }
    post.map { |po| topic_array.push(po.topic_id) unless topic_array.include?(po.topic_id) }

    tag.each do |t|
      topicwithtag = TopicWithTag.where(tag_id: t.id)
      topicwithtag.map { |twt| topic_array.push(twt.topic_id) unless topic_array.include?(twt.topic_id)}
    end

    place.map { |pl| place_array.push(pl.id) unless place_array.include?(pl.id) }

    # Split words and check (2nd priority)
    text_array = text.split(" ")

    text_array.each do |ta|
      user_split = User.search_data(ta)
      topic_split = Topic.search_data(ta)
      post_split = Post.search_data(ta)
      tag_split = Tag.search_data(ta.downcase)
      place_split = Place.search_data(ta)

      user_split.map { |u| user_array.push(u.id) unless user_array.include?(u.id) }
      topic_split.map { |to| topic_array.push(to.id) unless topic_array.include?(to.id) }
      post_split.map { |po| topic_array.push(po.topic_id) unless topic_array.include?(po.topic_id) }

      tag_split.each do |t|
        topicwithtag = TopicWithTag.where(tag_id: t.id)
        topicwithtag.map { |twt| topic_array.push(twt.topic_id) unless topic_array.include?(twt.topic_id) }
      end

      place_split.map { |pl| place_array.push(pl.id) unless place_array.include?(pl.id) }
    end

    Place.where(id: place_array).each do |pa|
      places_data.push(pa)
    end

    User.where(id: user_array).each do |temp_user|
      users_data.push({ id: temp_user.id, username: temp_user.username, points: temp_user.points })
    end

    render json: { topics: topic_array, users: users_data, places: places_data }
  end

  def retrieve_users
    userInfo = [ ]

    if params[:user_ids].present?
      userArray = params[:user_ids].split(",")

      User.where(id: userArray).each do |user|
        likedTopicArray = [ ]
        likedPostArray = [ ]
        liked_topics = ActionLog.where(type_name: "topic", action_type: "like", action_user_id: user.id)
        liked_posts = ActionLog.where(type_name: "post", action_type: "like", action_user_id: user.id)

        liked_topics.map { |lt| likedTopicArray.push(lt.type_id) } if liked_topics.present?
        liked_posts.map { |lp| likedPostArray.push(lp.type_id) } if liked_posts.present?

        userData = {
            user_id: user.id,
            username: user.username,
            liked_topics: likedTopicArray,
            liked_posts: likedPostArray
        }
        userInfo.push(userData)
      end

      render json: { users: userInfo }
    else
      render json: { error_msg: "Params user id(s) must be presented"}, status: 400
    end
  end

  # ************ API for FAVR  ************

  def background_retrieve
    if params[:choice] == "topics"
      topics = Topic.all

      render json: { topics: topics }
    elsif params[:choice] == "posts"
      topic = Topic.find(params[:topic_id])
      posts = topic.posts

      render json: { posts: posts }
    elsif params[:choice] == "media"
      mediaArray = [ ]
      posts = Post.all
      posts.map { |post| mediaArray.push(post) if post.post_type == Post::IMAGE or post.post_type == Post::AUDIO or post.post_type == Post::VIDEO }

      render json: mediaArray
    elsif params[:choice] == "tags"
      tagsArray = [ ]
      tags = Tag.all
      tags.map { |t| tagsArray.push( { id: t.id, tag: t.tag, tag_type: t.tag_type } ) }

      render json: { tags: tagsArray }
    elsif params[:choice] == "places"
      placesArray = [ ]
      places = Place.all
      places.map { |place| placesArray.push(place) if place.source == 0 or place.source == 2 or place.source == 4 }

      render json: { places: placesArray }
    elsif params[:choice] == "luncheon"
      topics = Topic.where(topic_type: 7)

      render json: { topics: topics }
    end
  end

  def retrieve_history
    topicArray = [ ]
    luncheonTopicArray = [ ]
    postArray = [ ]
    mediaArray = [ ]
    tagArray = [ ]

    if params[:history_id].present?
      last_history = Historychange.last
      current_history = Historychange.find(params[:history_id])

      if params[:choice] == "topic"
        historyArray = Historychange.where(["id > ? AND id <= ? AND type_name = ?", current_history, last_history, "topic"])

        historyArray.each do |historyChange|
          if historyChange.type_action == "create"
            topicArray.push({ topic: Topic.find(historyChange.type_id), status: "created"})
          elsif historyChange.type_action == "update"
            topicArray.push({ topic: Topic.find(historyChange.type_id), status: "updated"})
          elsif historyChange.type_action == "delete"
            topicArray.push({ topic: { topic_id: historyChange.type_id }, status: "deleted"})
          end
        end

        render json: { topics: topicArray }
      elsif params[:choice] == "post" or params[:choice] == "media"
        historyArray = Historychange.where(["id > ? AND id <= ? AND type_name = ?", current_history, last_history, "post"])

        historyArray.each do |historyChange|
          post = Post.find(historyChange.type_id)

          if historyChange.type_action == "create" or historyChange.type_action == "update"
            mediaArray.push( { media: post, status: "updated" } ) unless post.post_type == Post::TEXT
            postArray.push({ post: post, status: "updated" })
          elsif historyChange.type_action == "delete"
            mediaArray.push( { media: post, status: "deleted" } ) unless post.post_type == Post::TEXT
            postArray.push({ post: { post_id: historyChange.type_id }, status: "deleted" })
          end
        end

        render json: { posts: postArray } if params[:choice] == "post"
        render json: { media: mediaArray } if params[:choice] == "media"
      elsif params[:choice] == "tag"
        historyArray = Historychange.where(["id > ? AND id <= ? AND type_name = ?", current_history, last_history, "tag"])

        historyArray.each do |historyChange|
          if historyChange.type_action == "create" or historyChange.type_action == "update"
            tagArray.push({ tag: Tag.find(historyChange.type_id), status: "updated" })
          elsif historyChange.type_action == "delete"
            tagArray.push({ tag: { tag_id: historyChange.type_id }, status: "deleted" })
          end
        end

        render json: { tags: tagArray }
      elsif params[:choice] == "luncheon"
        historyArray = Historychange.where(["id > ? AND id <= ? AND type_name = ?", current_history, last_history, "topic"])

        historyArray.each do |historyChange|
          if historyChange.type_action == "create" or historyChange.type_action == "update"
            topic = Topic.find(historyChange.type_id)
            luncheonTopicArray.push({ topic: topic, status: "updated"}) if topic.topic_type == Topic::LUNCHEON
          elsif historyChange.type_action == "delete"
            luncheonTopicArray.push({ topic: { topic_id: historyChange.type_id }, status: "deleted" })
          end
        end

        render json: { topics: luncheonTopicArray }
      else
        render json: { status: false }
      end
    end
  end

  def latest_history
    if Historychange.last.present?
      render json: { history_id: Historychange.last.id }
    else
      render json: { status: false }
    end
  end

  def posts_retrieve
    topic = Topic.find(params[:topic_id])
    posts = topic.posts.first(15).sort
    check_posts = topic.posts.first(16).sort

    if posts.count != 15
      render json: { posts: posts, load: false}
    elsif posts.count == 15
      if check_posts.count == 16
        render json: {posts: posts, load: true}
      else
        render json: {posts: posts, load: false}
      end
    end
  end

  def retrieve_posts_in_range
    if params[:from_post_id].present?
      earlier_posts = Topic.find(params[:topic_id]).posts.where(["id < ?", params[:to_post_id]])
      posts = Topic.find(params[:topic_id]).posts.where(["id < ? AND id >= ?", params[:from_post_id], params[:to_post_id]])

    end
  end

  def segmented_posts_retrieve
    topic = Topic.find(params[:topic_id])
    posts = topic.posts.where(["id <?", params[:post_id]]).first(15)
    check_posts = topic.posts.where(["id < ?", params[:post_id]]).first(16)
    if posts.count != 15
      render json: { posts: posts, load: false}
    elsif posts.count != 15
      if check_posts.count == 16
        render json: { posts: posts, load: true}
      else
        render json: { posts: posts, load: false}
      end
    end
  end

  def retrieve_posts_history
    postArray = [ ]
    if params[:history_id].present? and params[:topic_id].present?
      last_history = Historychange.last
      current_history = Historychange.find(params[:history_id])

      historyArray = Historychange.where(["id > ? AND id <= ? AND type_name = ? AND parent_id = ?", current_history, last_history, "post", params[:topic_id]])

      historyArray.each do |historyChange|
        if (historyChange.type_action == "create" or historyChange.type_action == "update")
          postArray.push({ post: Post.find(historyChange.type_id), status: "updated" })
        elsif (historyChange.type_action == "delete")
          postArray.push({ post: { post_id: historyChange.type_id }, status: "deleted" })
        end
      end

      render json: { posts: postArray }
    else
      render json: { status: false }
    end
  end

  def posts_retrieve_for_user
    if params[:post_id].present?
      posts = User.find(params[:user_id]).posts.where(["id < ?", params[:post_id]]).first(15)
      check_posts = User.find(params[:user_id]).posts.where(["id < ?", params[:post_id]]).first(16)

      if posts.count != 15
        render json: { posts: posts, load: false }
      elsif posts.count == 15
        if check_posts.count == 16
          render json: { posts: posts, load: true }
        else
          render json: { posts: posts, load: false }
        end
      end
    else
      posts = User.find(params[:user_id]).posts.first(15)
      check_posts = User.find(params[:user_id]).posts.first(16)

      if posts.count != 15
        render json: { posts: posts, load: false }
      elsif posts.count == 15
        if check_posts.count == 16
          render json: { posts: posts, load: true }
        else
          render json: { posts: posts, load: false }
        end
      end
    end
  end

  def retrieve_carmic_user
    #User.update_latlng

    @users =User.where("data -> 'color' != ''")
    @hello = "hello there"
    #@users = Place.all

    @hash = Gmaps4rails.build_markers(@users) do |user, marker|
      marker.lat user.last_known_latitude
      marker.lng user.last_known_longitude
      marker.infowindow user.data["plate_number"]

      marker.picture({
                         url: "..//assets/red_car.png#red",
                         width: 30,
                         height: 80
                     })

      marker.json({
                      custom_marker: "<div class='marker_icon' style='background: #"+user.data["color"]+"'><img src='#{"..//assets/CarMask.png"}'></div>" ,
                      marker_id: user.id
                  })
    end
    render json: { marker: @hash}
  end

  def incident_and_breakdown
    full_path = 'http://datamall.mytransport.sg/ltaodataservice.svc/IncidentSet'
    url = URI.parse(full_path)
    req = Net::HTTP::Get.new(url.path, initheader = {"accept" =>"application/json", "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==", "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
    con = Net::HTTP.new(url.host, url.port)
    #con.use_ssl = true
    r = con.start {|http| http.request(req)}

    p "get incident list"


    @request_payload = JSON.parse r.body


    @accident = []
    @roadwork = []
    @vehiclebreakdown = []
    @weather = []
    @obstacle = []
    @roadblock = []
    @heavytraffic = []
    @misc = []
    @diversion = []
    @unattendedvehicle = []

    #p "incident count"
    #p @request_payload["d"].count
    #p "++++++++++"

    @request_payload["d"].each do |data|

      if data["Type"] == "Accident"
        @accident.push(data)

      elsif data["Type"] == "Road Work"
        @roadwork.push(data)

      elsif data["Type"] == "Vehicle Breakdown"
        @vehiclebreakdown.push(data)

      elsif data["Type"] == "Weather"
        @weather.push(data)

      elsif data["Type"] == "Obstacle"
        @obstacle.push(data)

      elsif data["Type"] == "Road Block"
        @roadwork.push(data)

      elsif data["Type"] == "Heavy Traffic"
        @heavytraffic.push(data)

      elsif data["Type"] == "Misc."
        @misc.push(data)

      elsif data["Type"] == "Diversion"
        @diversion.push(data)

      elsif data["Type"] == "Unattended Vehicle"
        @unattendedvehicle.push(data)

      end
    end

    #p "***************"
    #p "Accident"
    #p @accident
    #p @accident.count
    #p "------------------"
    #p "Road Work"
    #p @roadwork
    #p @roadwork.count
    #p "------------------"
    #p "Vehicle Breakdown"
    #p @vehiclebreakdown
    #p @vehiclebreakdown.count
    #p "------------------"
    #p "Weather"
    #p @weather
    #p @weather.count
    #p "------------------"
    #p "Obstacle"
    #p @obstacle
    #p @obstacle.count
    #p "------------------"
    #p "Road Block"
    #p @roadblock
    #p @roadblock.count
    #p "------------------"
    #p "Heavy Traffic"
    #p @heavytraffic
    #p @heavytraffic.count
    #p "Misc"
    #p @misc
    #p @misc.count
    #p "------------------"
    #p "Diversion"
    #p @diversion
    #p @diversion.count
    #p "------------------"
    #p "Unattended Vehicle"
    #p @unattendedvehicle
    #p @unattendedvehicle.count
    #p "------------------"

    @request_payload["d"].each do |data|
      p type = data["Type"]
      if type == "Accident" || type == "Vehicle Breakdown"  || type == "Weather" || type == "Heavy Traffic"

        if type == "Vehicle Breakdown"
          type = "VehicleBreakdown"
        elsif type == "Heavy Traffic"
          type = "HeavyTraffic"
        end

        message  = data["Message"]  # "(2/2)11:24 Vehicle breakdown on KJE (towards BKE) before Sungei Tengah Exit."
        inc_datetime= message.match(" ").pre_match #(2/2)11:24
        message= message.match(" ").post_match
        inc_date = inc_datetime.scan(/\(([^\)]+)\)/).last.first   # "2/2"
        current_year =  Time.now.strftime("%Y")
        inc_date = inc_date+"/"+current_year
        accidentDate = Date.parse(inc_date).strftime("%d %B %Y")
        inc_time =  inc_datetime.gsub(/\(.*\)/, "")
        accidentDateTIme = DateTime.parse(inc_time).strftime("%H:%M:%S %d-%B-%Y")

        p "----------------------"
        p type
        p message
        p accidentDate
        p accidentDateTIme
        p latitude = data["Latitude"]
        p longitude=data["Longitude"]
        p summary=data["Summary"]
        p "**********"

        sg_accident = SgAccidentHistory.where(message: message).take

        if sg_accident.nil?
          p "add new record"
          SgAccidentHistory.create(type:type,message: message, accident_datetime: accidentDateTIme, latitude:latitude, longitude:longitude, summary:summary )


        end


      end


    end

    render json: { data: @request_payload}

  end


end
