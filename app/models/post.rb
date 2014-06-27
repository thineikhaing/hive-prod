require 'obscenity/active_model'

class Post < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user
  delegate :username, to: :user

  # Setup hstore
  store_accessor :data

  attr_accessible :content, :post_type, :data, :created_at, :user_id, :topic_id
  enums %w(TEXT)
  validates :content, presence: true
  validates :content, obscenity: { sanitize: true, replacement: "snork" }

  def as_json(options=nil)
    super(only: [:id, :topic_id, :content, :created_at, :user_id, :post_type,:data], methods: [:username])
  end


  def broadcast_other_app
      data = {
          id: self.id,
          topic_id: self.topic_id,
          content: self.content,
          created_at: self.created_at,
          user_id: self.user_id,
          username: self.username,
          post_type: self.post_type,
          data: self.data
      }
    Pusher[self.topic_id].trigger_async("broadcast", data)
  end

  def broadcast_hive
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        created_at: self.created_at,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
    }
    Pusher[self.topic_id].trigger_async("broadcast", data)
  end

end
