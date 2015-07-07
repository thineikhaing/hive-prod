class CarmicController < ApplicationController
  def index
    @users =User.where("data -> 'color' != ''")
    @car_action_logs = CarActionLog.order("created_at desc")

    hiveapp = HiveApplication.find_by_app_name("Carmmunicate")
    @topics= Topic.where(hiveapplication_id: hiveapp.id)

    @hash = Gmaps4rails.build_markers(@users) do |user, marker|

      content = '<p class="hook">'+user.data["plate_number"]+'</p>'

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


    if params[:user_ids]

      @activeUsersArray = []
      p "user array"
      p user_arr = params[:user_ids]
      user_arr.each do |id|
        user = User.find(id)
        @activeUsersArray.push(user)
      end

      p "active users"
      p @activeUsersArray.count

    end

    if params[:cur_lat].present?

      @posts = nil
      get_all_topics(@latitude, @longitude)
      get_nearest_user(@latitude, @longitude)

    end

    if Rails.env.development?
      @url = "http://localhost:5000/api/downloaddata/retrieve_carmic_user"

    elsif Rails.env.staging?
      @url = "http://h1ve-staging.herokuapp.com/api/downloaddata/retrieve_carmic_user"
    else
      @url = "http://h1ve-production.herokuapp.com/api/downloaddata/retrieve_carmic_user"
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
      @topics_list = Topic.where(:place_id => places_id).order("id")
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
