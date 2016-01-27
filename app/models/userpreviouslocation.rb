class Userpreviouslocation < ActiveRecord::Base
  belongs_to :user

  ################
  # Self Methods #
  ################
  #attr_accessible :latitude, :longitude, :user_id, :radius, :created_at
  def as_json(option=nil)
    super(only: [:id, :latitude, :longitude, :user_id, :radius, :created_at])
  end
end
