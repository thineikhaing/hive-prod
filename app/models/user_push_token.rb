class UserPushToken < ActiveRecord::Base
  belongs_to  :user
  #attr_accessible :user_id, :push_token, :created_at, :updated_at
end