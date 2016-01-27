class IncidentHistory < ActiveRecord::Base
  has_many :users


  #attr_accessible :host_id, :peer_id, :host_data, :peer_data
end
