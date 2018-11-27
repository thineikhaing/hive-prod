class Trip < ApplicationRecord

  belongs_to :user
  belongs_to :depart, class_name: "Place", foreign_key: "start_place_id",primary_key: :id
  belongs_to :arrive, class_name: "Place", foreign_key: "end_place_id",primary_key: :id


  # Setup hstore
  store_accessor :data


end
