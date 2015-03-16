class TopicInvitees < ActiveRecord::Base
  attr_accessible :invitee_email, :topic_id
end
