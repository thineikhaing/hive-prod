class Post < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user

  # Setup hstore
  store_accessor :data

  attr_accessible :content, :post_type, :data, :created_at, :user_id, :topic_id

end
