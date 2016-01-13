class RouteLog < ActiveRecord::Base
  TRANSPORT = ["bus",
               "train",
               "taxi",
               "walk",
               "shared",
               "cycle"
  ]

  attr_accessible :user_id, :start_address, :end_address, :start_latitude, :start_longitude, :end_latitude, :end_longitude, :start_time, :end_time, :transport_type
end
