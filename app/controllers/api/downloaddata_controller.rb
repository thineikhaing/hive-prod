class Api::DownloaddataController < ApplicationController


  def initial_retrieve
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      params[:radius].present? ? radius = params[:radius] : radius = nil
      if hiveApplication.present?
        topics = Place.nearest_topics_within(params[:latitude], params[:longitude], radius, hiveApplication.id)
        if hiveApplication.id ==1 #Hive Application
          render json: { topics: JSON.parse(topics.to_json())}
        elsif hiveApplication.devuser_id==1 and hiveApplication.id!=1 #All Applications under Herenow account except Hive
          render json: { topics: JSON.parse(topics.to_json(content: true))}
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
    render json: {apps: JSON.parse(HiveApplication.all.to_json(:test => "true")) }
  end

  def retrieve_topics_by_app_key
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveApplication.present?
        topics = Topic.find_by_hiveapplication_id(hiveApplication.id)
        render json: { topics: JSON.parse(topics.to_json())}
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
      topicwithtag.map { |twt| topic_array.push(twt.topic_id) unless topic_array.include?(twt.topic_id) }
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
      users_data.push({ id: temp_user.id, username: temp_user.username, points: temp_user.point })
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
      render json: { error_msg: "Params user id(s) must be presented" } , status: 400
    end
  end

end
