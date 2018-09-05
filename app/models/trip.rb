class Trip < ApplicationRecord

  belongs_to :user
  belongs_to :depatures, class_name: "Place", foreign_key: "start_place_id",primary_key: :id
  belongs_to :arrivals, class_name: "Place", foreign_key: "end_place_id",primary_key: :id

  # Setup hstore
  store_accessor :data

  
end
