class UserAccount < ActiveRecord::Base
  #attr_accessible :user_id, :account_type, :linked_account_id, :priority,:created_at, :updated_at

  belongs_to :user
end