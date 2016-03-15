class Api::Hivev2Controller < ApplicationController

  def get_topic_by_latlon

    latestTopics = [ ]
    latestTopicUser = [ ]
    lat = params[:cur_lat]
    lng = params[:cur_long]
    app = HiveApplication.find_by_api_key(params[:api_key])

    places =  Place.nearest(lat,lng,2)

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

    render json: {status: "ok!", latestTopics: latestTopics, latestTopicUsers: latestTopicUser}
  end
end