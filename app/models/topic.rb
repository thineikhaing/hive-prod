class Topic < ActiveRecord::Base
  belongs_to :hiveapplication
  belongs_to :user

  # Setup hstore
  store_accessor :data

  attr_accessible :title, :topic_sub_type, :place_id, :place_id, :hiveapplication_id, :user_id, :data, :created_at

end
