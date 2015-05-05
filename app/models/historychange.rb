class Historychange < ActiveRecord::Base
  attr_accessible :type_name, :type_id, :type_action, :parent_id

  #def create_record(type, type_id, type_action, parent_id)
  #
  #  Historychange.create(type_name: type, type_id: type_id, type_action: type_action, parent_id: parent_id)
  #end

end
