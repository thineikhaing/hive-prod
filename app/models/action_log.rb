class ActionLog < ActiveRecord::Base
  #attr_accessible :action_type, :type_name, :type_id, :action_user_id, :created_at

  def create_record(type_name, type_id, action_type, action_user_id)
    ActionLog.create(type_name: type_name, type_id: type_id, action_type: action_type, action_user_id: action_user_id)
  end

end
