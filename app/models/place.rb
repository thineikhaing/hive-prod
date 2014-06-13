class Place < ActiveRecord::Base
  has_many :topics

  # Setup hstore
  store_accessor :data

  attr_accessible :name, :category, :address, :locality, :region, :neighbourhood, :chain_name, :country, :postal_code, :website_url, :chain_name, :contact_number, :img_url, :source, :source_id, :latitude, :longitude, :user_id

  enums %w(HERENOW USER VENDOR FACTUAL MRT UNKNOWN PRIVATE)


  # Returns nearest topics within n latitude, n longitude and n radius (For downloaddata controller)
  def self.nearest_topics_within(latitude, longitude, radius)
    radius = 1 if radius.nil?

    box = Geocoder::Calculations.bounding_box("#{latitude}, #{longitude}", radius, {units: :km})
    places = Place.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])

    topics_array = [ ]

    places.each do |place|
      if place.topics.present?
        place.topics.each do |topic|
          topics_array.push(topic)
        end
      end
    end

    topics_array
  end
end
