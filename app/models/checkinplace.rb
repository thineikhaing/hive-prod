class Checkinplace < ActiveRecord::Base
  belongs_to :user

  ################
  # Self Methods #
  ################
  attr_accessible :user_id,:place_id, :created_at, :updated_at


  def as_json(option=nil)
    super(only: [:id, :place_id, :user_id, :created_at])
  end
end
