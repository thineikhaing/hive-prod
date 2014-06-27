class Topic < ActiveRecord::Base
  belongs_to :hiveapplication
  belongs_to :user
  belongs_to :place

  has_many  :posts
  # Setup hstore
  store_accessor :data

  attr_accessible :title, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :data, :created_at, :image_url

  def as_json(options=nil)
    super(only: [:id, :title, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url, :data, :created_at], methods: [:username])
  end

  def username
    User.find_by_id(self.user_id).username
  end

  def hive_broadcast

    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        username: username,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        hiveapplication_id: self.hiveapplication_id
    }

    Pusher["hive_channel"].trigger_async("new_topic", data)
  end

  def app_broadcast
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        username: username,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        hiveapplication_id: self.hiveapplication_id,
        data: self.data
    }
    channel_name = "hive_application_"+ self.hiveapplication_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("new_topic", data)
  end

end
