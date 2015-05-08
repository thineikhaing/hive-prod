class Historychange < ActiveRecord::Base
  attr_accessible :type_name, :type_id, :type_action, :parent_id

  belongs_to :topic

  class Post < ActiveRecord::Base
    after_initialize :readonly!
  end

  def readonly?
    false
  end

  #def create_record(type, type_id, type_action, parent_id)
  #  Historychange.create(type_name: type, type_id: type_id, type_action: type_action, parent_id: parent_id)
  #end

end
