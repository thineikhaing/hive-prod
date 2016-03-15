class Api::Hivev2Controller < ApplicationController

  def get_topic_by_latlon

    latestTopics = [ ]
    latestTopicUser = [ ]
    lat = params[:cur_lat]
    lng = params[:cur_long]
    app = HiveApplication.find_by_api_key(params[:api_key])

    places =  Place.nearest(lat,lng,1)

    if places.present?
      places_id = []
      places.each do |p|
        places_id.push p.id
      end
      latestTopics = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")

      latestTopics.each do |t|
        latestTopicUser.push(t.username)
      end
    end

    pop_topic = []
    pop_topic_posts = []

    if latestTopics.count > 0
      pop_topic = latestTopics.first
      pop_topic_posts = pop_topic.posts
    end

    render json: {status: "ok!", latestTopics: latestTopics, latestTopicUsers: latestTopicUser, pop_topic: pop_topic, pop_topic_posts: pop_topic_posts}
  end
end