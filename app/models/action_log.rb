class ActionLog < ActiveRecord::Base
  attr_accessible :action_type, :type_name, :type_id, :action_user_id, :created_at

end
