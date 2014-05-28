class Place < ActiveRecord::Base
  # Setup hstore
  store_accessor :data

  attr_accessible :name, :category, :address, :locality, :region, :neighbourhood, :chain_name, :country, :postal_code, :website_url, :chain_name, :contact_number, :img_url, :source, :source_id, :latitude, :longitude
end
