class Invitee < ActiveRecord::Base
  belongs_to :topic

  attr_accessible :invitation_code, :user_id, :topic_id
end
