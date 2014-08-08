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

  def self.nearest(latitude, longitude, radius)
    # Contains bottom-left and top-right corners
    radius = 0.3 unless radius.present?
    box = Geocoder::Calculations.bounding_box("#{latitude},#{longitude}", radius, {units: :km})
    Place.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])
  end


  def self.create_place_by_lat_lng(latitude, longitude,current_user)
    factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    query = factual.geocode(latitude,longitude).first

    if query.present?
      if query["address"].present?
        check = Place.find_by_address(query["address"])
        check.present? ? place = check : place = Place.create(name: query["address"], latitude:latitude, longitude: longitude, address: query["address"], postal_code: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
      elsif query["locality"].present?
        check = Place.find_by_address("Somewhere in #{query["locality"]}")
        check.present? ? place = check : place = Place.create(name: "Somewhere in #{query["locality"]}", latitude: latitude, longitude: longitude, address: "Somewhere in #{query["locality"]}", postal_code: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
      end
    else
      geocoder = Geocoder.search("#{latitude},#{longitude}").first

      if geocoder.present? and geocoder.country.present?
        p "present"
        check = Place.find_by_address("Somewhere in #{geocoder.country}")
        check2 = Place.find_by_address("Somewhere in the world")

        check.present? ? place = check : place = Place.create(name: "Somewhere in #{geocoder.country}", latitude: latitude, longitude: longitude, address: "Somewhere in #{geocoder.country}", source: Place::UNKNOWN, user_id: current_user.id)
      else
        p "we are the world"
        check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: latitude, longitude: longitude, address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
      end
    end
  end

end
