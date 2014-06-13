class Topic < ActiveRecord::Base
  belongs_to :hiveapplication
  belongs_to :user
  belongs_to :place

  has_many  :posts
  # Setup hstore
  store_accessor :data

  attr_accessible :title, :topic_sub_type, :place_id, :place_id, :hiveapplication_id, :user_id, :data, :created_at

  def as_json(options=nil)
    super(only: [:id, :title, :topic_sub_type, :place_id, :place_id, :hiveapplication_id, :user_id, :data, :created_at], methods: [:username])
  end

  def username
    User.find_by_id(self.user_id).username
  end
end
