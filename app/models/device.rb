class Device < ActiveRecord::Base
  attr_accessible :push_token, :user_id, :created_at
end
