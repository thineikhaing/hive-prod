class Trip < ApplicationRecord

  belongs_to :user
  belongs_to :depart, class_name: "Place", foreign_key: "start_place_id",primary_key: :id
  belongs_to :arrive, class_name: "Place", foreign_key: "end_place_id",primary_key: :id


  # Setup hstore
  store_accessor :data

  def delete_event_broadcast_hive
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        state: self.state,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        points: self.points,
        free_points:self.free_points,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }

    Pusher["hive_channel"].trigger_async("delete_topic", data)
  end


end
