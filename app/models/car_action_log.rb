class CarActionLog < ActiveRecord::Base
  belongs_to :user

  attr_accessible :user_id, :latitude, :longitude, :speed, :direction, :activity, :heartrate
  paginates_per 20
end
