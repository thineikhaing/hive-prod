require 'value_enums'

class Tag < ActiveRecord::Base
  attr_accessible :tag_type, :keyword, :created_at

  enums %w(NORMAL LOCATION)
end
