class Api::HivewebController < ApplicationController

  def get_all_topics_for_web


     lat = params[:lat]
     lng = params[:lng]
     places = Place.nearest(lat,lng,5)
    if places.present?
      places_id = []
      places.each do |p|
        places_id.push p.id
      end
      @topics_list = Topic.where(:place_id => places_id).order("id")
      if not @topics_list.nil?
        for topic in @topics_list
          #getting avatar url
          @topic_avatar_url = Hash.new
          if topic.offensive < 3 and topic.special_type == 3
            @topic_avatar_url[topic.id] = "assets/Avatars/Chat-Avatar-Admin.png"
          else
            username = topic.user.username
            p "get avatar"
            p get_avatar(username)
            p @topic_avatar_url[topic.id] =  @avatar_url

          end
        end
      end
    end

    p @topic_avatar_url

    @placesMap = Place.order("created_at DESC").reload
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

    @postcount = Hash.new
    @usercount = Hash.new
    @topic_tag =  Hash.new

    hive_pcount = 0
    hive_ucount = 0

    meal_pcount = 0
    meal_ucount = 0

    car_pcount = 0
    car_ucount = 0

    juice_pcount = 0
    juice_ucount  = 0

    if not @topics_list.nil?
    @topics_list.each do |data|
      post = Post.where("topic_id =?", data.id)
      user = post.select("count(distinct(user_id)) as usercount").take
      t_tag = TopicWithTag.select("topic_id, tags.keyword")
      .joins(:tag).where("topic_id =?", data.id).order("tags.keyword")

      t_tag = TopicWithTag.select("topic_id, tags.keyword").joins(:tag).where("topic_id = 38").order("tags.keyword")

      p "POST USER Count"
      p data.hiveapplication_id
      p "hive id"
      p @postcount[data.id] = post.count
      p @usercount[data.id] = user.usercount
      @topic_tag[data.id] = t_tag


      #
      @topic_tag[data.id]= t_tag

      #Hive APP

      if data.hiveapplication_id  == 1
        hivepost = Post.joins(:topic).where("topics.hiveapplication_id = '1'")
        hiveuser = hivepost.select("count(distinct(posts.user_id)) as usercount").take
        p "Hive Count"
        p hive_pcount = hivepost.count
        p hive_ucount = hiveuser.usercount

      end

      #MealBox APP

      if data.hiveapplication_id  == 2
        mealpost = Post.joins(:topic).where("topics.hiveapplication_id = '2'")
        mealuser = mealpost.select("count(distinct(posts.user_id)) as usercount").take
        p "MealBox Count"
        p meal_pcount = mealpost.count
        p meal_ucount = mealuser.usercount
      end

      #Carmmunicate APP

      if data.hiveapplication_id  == 3
        carpost = Post.joins(:topic).where("topics.hiveapplication_id = '3'")
        caruser = carpost.select("count(distinct(posts.user_id)) as usercount").take
        p "Carmmunicate Count"
        p car_pcount = carpost.count
        p car_ucount = caruser.usercount
      end

      #Juice APP

      if data.hiveapplication_id == 4
        p "Juice Count"
        juicepost = Post.joins(:topic).where("topics.hiveapplication_id = '4'")
        juiceuser = juicepost.select("count(distinct(posts.user_id)) as usercount").take
        p juice_pcount = juicepost.count
        p juice_ucount = juiceuser.usercount
      end

    end
    end
    topic = {  topic_list: @topics_list,
               topic_avatar: @topic_avatar_url ,
               places: @placesMap.as_json,
               latestTopicUser: @latestTopicUser,
               latestTopics: @latestTopics ,
               postcount: @postcount,
               usercount: @usercount,
               topic_tag: @topic_tag,
               hive_pcount: hive_pcount,
               hive_ucount: hive_ucount,
               meal_pcount: meal_pcount,
               meal_ucount: meal_ucount,
               car_pcount: car_pcount,
               car_ucount: car_ucount ,
               juice_pcount: juice_pcount,
               juice_ucount: juice_ucount

    }
    render :json => topic
  end

  def popular_topic

    p most_like_topic = Topic.select("*, max(likes)").group(:id).take
    username = most_like_topic.user.username
    @pop_avatar_url= get_avatar(username)

    p topicid = most_like_topic.id



    @topic_title = Topic.find(topicid).title


    @topic = Topic.where(id: topicid).first.reload
    p @posts = @topic.posts.includes(:user).sort #limits max 20 posts???



    @post_avatar_url = Hash.new

    @posts.each do |post|
      username = post.user.username
      get_avatar(username)
      @post_avatar_url[post.id] = (@avatar_url)
    end
    @topicid = Integer(topicid)

    #posts = {  pop_posts: @posts, pop_post_avatar_url: @post_avatar_url , postdistance: @postdistance, topic: @topic}

    render json: {popular_topic: most_like_topic,
                  pop_avatar_url: @pop_avatar_url,
                  pop_posts: @posts,
                  pop_post_avatar_url: @post_avatar_url}
  end

  def get_all_topics_for_place
    place_array = [ ]
    topicsInView_array = [ ]

    address = params[:add]

    lat1 = params[:lat]
    long1 = params[:lng]

    @place_array = params[:place_arr].split(',')

    #Retrieve the sticky topic
    #stickyTopic = Topic.where(:special_type => "3", :topic_type => 0)
    stickyTopic = Topic.where("special_type =? and topic_type in (?)", "3", [0,1,2,3])
    if @place_array.present?
      place_array = @place_array
      places= Place.where(:id=>@place_array)
      for pl in places
        topics = nil
        topics =  pl.topics.where("special_type<>?","3") if pl.topics.present?
        unless topics.nil?
          for topic in topics
            topicsInView_array.push(topic)
          end
        end
      end
      listOfTopics = topicsInView_array
      listOfTopics.sort! { |a,b| a.created_at <=> b.created_at }
      listOfTopics.reverse!
    end
    @topics_list= stickyTopic
    @topics_list+= listOfTopics
    @distance = Hash.new  # @distance[topicid, distance]
    @topic_avatar_url = Hash.new
    #adding avatar photo and calculate the distance from the current location
    if not @topics_list.nil?
      for topic in @topics_list
        #getting avatar url
        if topic.offensive < 3 and topic.special_type == 3
          @topic_avatar_url[topic.id] = "assets/Avatars/Chat-Avatar-Admin.png"
        else
          username = topic.user.username
          get_avatar(username)
          @topic_avatar_url[topic.id] = @avatar_url
        end

        #calculate distance from current location
        #set the current position
        location1 = [ ]
        location1.push (lat1)
        location1.push (long1)

        #set the topic position
        location2 = [ ]
        location2.push (topic.place.latitude)
        location2.push (topic.place.longitude)
        #@distance[topic.id] = get_distance(location1, location2,"topic")

        #the max no of characters to show the topic title is 50
        if topic.title.length > 45
          topic.title = topic.title[0..42] + "..."
        end
      end
      @post_lists = params[:id]
      if params[:id].present?
        get_all_posts(params[:id])
      end
    end

    @postcount = Hash.new
    @usercount = Hash.new
    @topic_tag =  Hash.new

    hive_pcount = 0
    hive_ucount = 0

    meal_pcount = 0
    meal_ucount = 0

    car_pcount = 0
    car_ucount = 0

    juice_pcount= 0
    juice_ucount = 0

    @topics_list.each do |data|
      post = Post.where("topic_id =?", data.id)
      user = post.select("count(distinct(user_id)) as usercount").take

      t_tag = TopicWithTag.select("topic_id, tags.keyword")
      .joins(:tag).where("topic_id =?", data.id).order("tags.keyword")

      p "POST USER Count"
      p data.hiveapplication_id
      p "hive id"
       @postcount[data.id] = post.count
       @usercount[data.id] = user.usercount
       @topic_tag[data.id] =  t_tag


      #Hive APP

      if data.hiveapplication_id  == 1
        hivepost = Post.joins(:topic).where("topics.hiveapplication_id = '1'")
        hiveuser = hivepost.select("count(distinct(posts.user_id)) as usercount").take
        p "Hive Count"
         hive_pcount = hivepost.count
         hive_ucount = hiveuser.usercount

      end

      #MealBox APP

      if data.hiveapplication_id  == 2
        mealpost = Post.joins(:topic).where("topics.hiveapplication_id = '2'")
        mealuser = mealpost.select("count(distinct(posts.user_id)) as usercount").take
        p "MealBox Count"
         meal_pcount = mealpost.count
         meal_ucount = mealuser.usercount
      end

      #Carmmunicate APP

      if data.hiveapplication_id  == 3
        carpost = Post.joins(:topic).where("topics.hiveapplication_id = '3'")
        caruser = carpost.select("count(distinct(posts.user_id)) as usercount").take
        p "Carmmunicate Count"
         car_pcount = carpost.count
         car_ucount = caruser.usercount
      end

      #Juice APP

      if data.hiveapplication_id == 4
        p "Juice Count"
        juicepost = Post.joins(:topic).where("topics.hiveapplication_id = '4'")
        juiceuser = juicepost.select("count(distinct(posts.user_id)) as usercount").take
        p juice_pcount = juicepost.count
        p juice_ucount = juiceuser.usercount
      end

    end

    topic = {  topic_list: @topics_list,
               topic_avatar: @topic_avatar_url,
               postcount: @postcount,
               usercount: @usercount,
               topic_tag: @topic_tag,
               hive_pcount: hive_pcount,
               hive_ucount: hive_ucount,
               meal_pcount: meal_pcount,
               meal_ucount: meal_ucount,
               car_pcount: car_pcount,
               car_ucount: car_ucount,
               juice_pcount: juice_pcount,
               juice_ucount: juice_ucount
    }
    render json: topic

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

  def all_topics
    place_array = [ ]
    topicsInView_array = [ ]
    lat1 =Float(@latitude)
    long1 =Float(@longitude)

    #Retrieve the sticky topic
    #stickyTopic = Topic.where(:special_type => "3", :topic_type => 0)
    stickyTopic = Topic.where("special_type =? and topic_type in (?)", "3", [0,1,2,3])
    if @place_array.present?
      place_array = @place_array
      places= Place.where(:id=>@place_array)
      for pl in places
        topics = nil
        topics =  pl.topics.where("special_type<>?","3") if pl.topics.present?
        unless topics.nil?
          for topic in topics
            topicsInView_array.push(topic)
          end
        end
      end
      listOfTopics = topicsInView_array
      listOfTopics.sort! { |a,b| a.created_at <=> b.created_at }
      listOfTopics.reverse!
    end
    @topics_list= stickyTopic
    @topics_list+= listOfTopics
    @distance = Hash.new  # @distance[topicid, distance]
    @topic_avatar_url = Hash.new
    #adding avatar photo and calculate the distance from the current location
    if not @topics_list.nil?
      for topic in @topics_list
        #getting avatar url
        if topic.offensive < 3 and topic.special_type == 3
          @topic_avatar_url[topic.id] = "assets/Avatars/Chat-Avatar-Admin.png"
        else
          username = topic.user.username
          get_avatar(username)
          @topic_avatar_url[topic.id] =  @avatar_url
        end

        #calculate distance from current location
        #set the current position
        location1 = [ ]
        location1.push (lat1)
        location1.push (long1)

        #set the topic position
        location2 = [ ]
        location2.push (topic.place.latitude)
        location2.push (topic.place.longitude)
        @distance[topic.id] = get_distance(location1, location2,"topic")

        #the max no of characters to show the topic title is 50
        if topic.title.length > 45
          topic.title = topic.title[0..42] + "..."
        end
      end
      @post_lists = params[:id]
      if params[:id].present?
        get_all_posts(params[:id])
      end
    end
  end

  def get_all_posts_for_web
    topicid = params[:topicid]
    p lat = params[:lat]
    p lng = params[:lng]
    @topic_title = Topic.find(topicid).title
    lat1 =Float(lat)
    long1 =Float(lng)
    @postdistance = Hash.new  # @distance[postid, distance]

    location1 = [ ]
    location1.push (lat1)
    location1.push (long1)

    @topic = Topic.where(id: topicid).first.reload
    @posts = @topic.posts.includes(:user).sort #limits max 20 posts???
    @post_avatar_url = Hash.new

    @posts.each do |post|
      username = post.user.username
      get_avatar(username)
      @post_avatar_url[post.id] = (@avatar_url)
      #get the post location
      location2 = [ ]
      location2.push (post.latitude)
      location2.push (post.longitude)
      @postdistance[post.id] = get_distance(location1, location2,"")
    end
    @topicid = Integer(topicid)
    posts = {  posts: @posts, post_avatar_url: @post_avatar_url , postdistance: @postdistance, topic: @topic}
    render :json => posts

  end

  def get_distance(location1, location2, type)
    distance_msg = ""
    distance =  Geocoder::Calculations.distance_between(location1, location2)
    if type == "topic"
      distance_in_meter = Float(distance)* 1000
      if Float(distance_in_meter) <= 100
        distance_msg = "nearby"
      elsif Float(distance_in_meter)>= 1000   #change to kilometer from meter
        distance_msg =(Float(distance_in_meter)/1000).round(2).to_s + " km away"
      else
        distance_msg = distance_in_meter.round(0).to_s + " meters away"
      end
    else
      if Float(distance) <= 1
        distance_msg = "nearby"
      elsif Float(distance)>= 1   #change to kilometer from meter
        distance_msg =(Float(distance)).round(2).to_s + " km away"
      end
    end
    #if Float(distance_in_meter) < 5
    #  distance_msg = "here"
    return distance_msg
  end


  def create_post


    user = User.find(params[:user])
    if user.present?
      @post = user.posts.build({ topic_id: params[:topic_id], content: params[:post] })
    end

    #@post.content = Rinku.auto_link(filter_profanity(@post.content))
    if @post.content.length > 255 #check for max length of content
      flash.now[:notice] =  'The max length message is 255'
    elsif @post.content.length == 0  #check content is blank?
      flash.now[:notice] = 'Please enter the message'
    else
      if @post.save
        #history = Historychange.new
        #history.create_record("post", @post.id, "create", @post.topic_id)
        #history.create_record("topic", @post.topic.id, "update", @post.topic.place_id)

        @post.latitude = params[:lat].to_f
        @post.longitude = params[:lng].to_f
        #factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
        #factual_result = factual.table("global").geo("$circle" => {"$center" => [@post.latitude, @post.longitude], "$meters" => 1000}).first
        #@post.address = factual_result["address"]

        p params[:topic_id]

        p "Topic ID"
        p @post.topic_id = params[:topic_id]

        @post.save!
        @post.broadcast

      else
        flash.now[:notice] = 'Error in creating message'
      end
    end
    render :json => {status: "Created!"}

    #respond_to do |format|
    #  get_all_posts (params[:id])
    #  format.js
    #end
  end
  
  def map_view
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
    #gon.watch.newplaces = @placesMap
    mapView =  {places: @placesMap.as_json,
               latestTopicUser: @latestTopicUser,
               latestTopics: @latestTopics}
              
    render :json =>mapView
    
  end
  
  def sign_in
    if params[:email].present? and params[:password].present?
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
        render json: {:error => "User Name and Password is mismatched!"}

      end
      
    else
      render json: {error_msg: "Params email and password must be presented"} , status: 400
    end
    
  end
  
  def sign_up

    if params[:email] and params[:password] 
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

  def get_topics_for_hive

  end

  def get_topics_for_mealbox

  end

  def get_topics_for_car
    @topics_list= Topic.where("hiveapplication_id = '3'")

    @topic_avatar_url = Hash.new
    #adding avatar photo and calculate the distance from the current location
    if not @topics_list.nil?
      for topic in @topics_list
        #getting avatar url
        if topic.offensive < 3 and topic.special_type == 3
          @topic_avatar_url[topic.id] = "assets/Avatars/Chat-Avatar-Admin.png"
        else
          username = topic.user.username
          get_avatar(username)
          @topic_avatar_url[topic.id] = @avatar_url
        end
    end

    @postcount = Hash.new
    @usercount = Hash.new
    @topic_tag =  Hash.new

    @topics_list.each do |data|
      post = Post.where("topic_id =?", data.id)
      user = post.select("count(distinct(user_id)) as usercount").take
      t_tag = TopicWithTag.select("topic_id, tags.keyword").order("tags.keyword")
      .joins(:tag).where("topic_id =?", data.id)

      p "POST USER Count"
      p data.hiveapplication_id
      p "hive id"
      @postcount[data.id] = post.count
      @usercount[data.id] = user.usercount
      @topic_tag[data.id] =  t_tag

    end

    topic = {  topic_list: @topics_list,
               topic_avatar: @topic_avatar_url,
               postcount: @postcount,
               usercount: @usercount,
               topic_tag: @topic_tag

    }
    render json: topic

    end

  end



  def get_topics_by_tag

    tag = Tag.find_by_keyword(params[:keyword])


    @topics_list = Topic.select("topics.id , title , topics.created_at, offensive, special_type, topics.user_id ,hiveapplication_id,place_id")
    .joins(:topic_with_tags).where("topic_with_tags.tag_id=?", tag.id)

    @topic_avatar_url = Hash.new
    #adding avatar photo and calculate the distance from the current location
    if not @topics_list.nil?
      for topic in @topics_list
        #getting avatar url
        if topic.offensive < 3 and topic.special_type == 3
          @topic_avatar_url[topic.id] = "assets/Avatars/Chat-Avatar-Admin.png"
        else
          username = topic.user.username
          get_avatar(username)
          @topic_avatar_url[topic.id] = @avatar_url
        end
      end

      @postcount = Hash.new
      @usercount = Hash.new
      @topic_tag =  Hash.new

      @topics_list.each do |data|
        post = Post.where("topic_id =?", data.id)
        user = post.select("count(distinct(user_id)) as usercount").take
        p t_tag = TopicWithTag.select("topic_id, tags.keyword").order("tags.keyword").joins(:tag).where("topic_id =?", data.id)

        p "POST USER Count"
        p data.hiveapplication_id
        p "hive id"
        @postcount[data.id] = post.count
        @usercount[data.id] = user.usercount
        p @topic_tag[data.id] =  t_tag

      end

      topic = {  topic_list: @topics_list,
                 topic_avatar: @topic_avatar_url,
                 postcount: @postcount,
                 usercount: @usercount,
                 topic_tag: @topic_tag

      }
      render json: topic

    end

  end

end
