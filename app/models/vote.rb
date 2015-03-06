class Vote < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user
  belongs_to :suggesteddate

  attr_accessible :vote, :topic_id, :selected_datetime, :suggesteddate_id, :user_id

  enums %w(MAYBE YES NO)
end
