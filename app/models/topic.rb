class Topic < ActiveRecord::Base
  belongs_to :hiveapplication
  belongs_to :user
  belongs_to :place

  has_many  :posts
  # Setup hstore
  store_accessor :data

  attr_accessible :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :data, :created_at, :image_url, :width, :height, :value, :unit

  def as_json(options=nil)
    super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :created_at], methods: [:username, :place_information])
  end

  def username
    User.find_by_id(self.user_id).username
  end

  def place_information
    if self.place_id.present? and self.place_id > 0
      place = Place.find(self.place_id)

      { id: place.id, name: place.name, latitude: place.latitude, longitude: place.longitude, address: place.address, category: place.category, source: place.source, source_id: place.source_id, user_id: place.user_id, country: place.country, postal_code: place.postal_code, chain_name: place.chain_name, contact_number: place.contact_number, img_url: place.img_url,locality: place.locality, region: place.region, neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end
  end

  def hive_broadcast

    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        username: username,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit
    }

    Pusher["hive_channel"].trigger_async("new_topic", data)
  end

  def app_broadcast
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        username: username,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        data: self.data
    }
    channel_name = "hive_application_"+ self.hiveapplication_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("new_topic", data)
  end

end
