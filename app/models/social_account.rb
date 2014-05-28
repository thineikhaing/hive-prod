class SocialAccount < ActiveRecord::Base
  attr_accessible :account_type, :account_id, :user_id
end
