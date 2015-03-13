class Suggesteddate < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user
  has_many :votes

  attr_accessible :topic_id, :suggested_datetime, :invitation_code ,:user_id
end
