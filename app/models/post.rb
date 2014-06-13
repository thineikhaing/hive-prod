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
    super(only: [:id, :topic_id, :content, :created_at, :user_id, :post_type], methods: [:username])
  end
end
