class Place < ActiveRecord::Base
  has_many :topics

  # Setup hstore
  store_accessor :data

  attr_accessible :name, :category, :address, :locality, :region, :neighbourhood, :chain_name, :country, :postal_code, :website_url, :chain_name, :contact_number, :img_url, :source, :source_id, :latitude, :longitude, :user_id

  enums %w(HERENOW USER VENDOR FACTUAL MRT UNKNOWN PRIVATE)


  # Returns nearest topics within n latitude, n longitude and n radius (For downloaddata controller)
  def self.nearest_topics_within(latitude, longitude, radius, hive_id)
    radius = 1 if radius.nil?
    center_point = [latitude.to_f, longitude.to_f]
    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
    places = Place.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])

    topics_array = [ ]

    places.each do |place|
      if place.topics.present?
        place.topics.each do |topic|
          if hive_id==1
            topics_array.push(topic)
          else
            if topic.hiveapplication_id == hive_id
              topics_array.push(topic)
            end
          end

        end
      end
    end
    topics_array
  end

  def add_record(name, latitude, longitude, address, source, source_id, place_id, user_id, auth_token, choice,img_url,category="",locality="",country="",postcode="")
    factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    user = User.find(user_id)
    #category = ""
    neighborhood = ""
    website = ""
    tel = ""
    category = "" unless category.present?
    if auth_token.present?
      if place_id.present?
        place = Place.find(place_id)
        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        if img_url.present?
          place.img_url = img_url
          place.save!
        end
        if locality.present?
          place.locality = locality
          place.save!
        end
        if country.present?
          place.country = country
          place.save!
        end
        if postcode.present?
          place.postcode = postcode
          place.save!
        end
        user.check_in_time = Time.now
        user.save!
        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }
      elsif source_id.present?
        factual_result = factual.table("places").filters("factual_id" => source_id.to_s).first

        if factual_result["category_labels"].present?
          factual_result["category_labels"].each do |fr|
            if choice== "luncheon"
              #fr.each do |frtype|
              #  if frtype == "Food and Dining"
              #    category = frtype
              #  end
              #end
              category << "Food and Dining"
            else
              if category.nil?
                category = ""
              end
              category.present? ? category << "," << fr : category << fr.first.to_s
            end
          end
        end

        if factual_result["neighborhood"].present?
          factual_result["neighborhood"].each do |fr|
            neighborhood.present? ? neighborhood << "," << fr : neighborhood << fr
          end
        end

        factual_result["website"].present? ? website = factual_result["website"] : website = ""
        factual_result["tel"].present? ? tel = factual_result["tel"] : tel = ""

        place = Place.create(name: factual_result["name"], latitude: factual_result["latitude"], longitude: factual_result["longitude"], address: factual_result["address"], country: factual_result["country"], category: category, locality: factual_result["locality"], postal_code: factual_result["postcode"], region: factual_result["region"], website_url: website, source: 3, source_id: source_id, user_id: user_id,img_url: img_url)
        #end
        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        user.check_in_time = Time.now
        user.save!
        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }
      else
        place = ""
        private_place = ""
        check_records = Place.nearest(latitude, longitude, 0.5)

        check_records.each do |cr|
          private_place = cr if cr.user_id == user_id and cr.source == 6
          place = cr if cr.name.downcase == name.downcase
        end

        if private_place.present?
          return { place: private_place, status: 71 }
        else
          if choice == "luncheon"
            place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, category: "Food and Dining",img_url: img_url,country: country,postcode: postcode,locality: locality) unless place.present?
          else
            place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, img_url: img_url,category: category,country: country,postcode: postcode,locality: locality) unless place.present?
          end

          Checkinplace.create(place_id: place.id, user_id: user_id)
          user.last_known_latitude =  place.latitude
          user.last_known_longitude = place.longitude
          user.check_in_time = Time.now
          user.save!
          Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

          return { place: place, status: 70 }
        end
      end
    else
      place = self.class.check_for_records(latitude, longitude)

      if place.present?
        return { place: place, status: 70 }
      else
        factual_result = factual.table("global").geo("$circle" => {"$center" => [latitude, longitude], "$meters" => 1000}).first

        if factual_result["category_labels"].present?
          factual_result["category_labels"].each do |fr|
            category.present? ? category << "," << fr : category << fr.first
          end
        end

        if factual_result["neighborhood"].present?
          factual_result["neighborhood"].each do |fr|
            neighborhood.present? ? neighborhood << "," << fr : neighborhood << fr
          end
        end

        factual_result["website"].present? ? website = factual_result["website"] : website = ""
        factual_result["tel"].present? ? tel = factual_result["tel"] : tel = ""
        new_place = Place.create(name: factual_result["name"], latitude: factual_result["latitude"], longitude: factual_result["longitude"], address: factual_result["address"], country: factual_result["country"], category: category, locality: factual_result["locality"], postal_code: factual_result["postcode"], region: factual_result["region"],  website_url: website, source: 3, source_id: source_id, user_id: user_id,img_url: img_url)

        return { place: new_place, status: 70 }
      end
    end
  end

  def self.nearest(latitude, longitude, radius)
    # Contains bottom-left and top-right corners
    radius = 0.3 unless radius.present?
    center_point = [latitude.to_f, longitude.to_f]
    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
    Place.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])
  end

  # Search the database for related places names

  def self.search_data(search)
    if search
      #find(:all, :conditions => ['lower(name) LIKE ?', "%#{search.downcase}%"])
      where("lower(name) like ?", "%#{search.downcase}%")
    else
      find(:all)
    end
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
        check = Place.find_by_address("Somewhere in #{geocoder.country}")
        check2 = Place.find_by_address("Somewhere in the world")

        check.present? ? place = check : place = Place.create(name: "Somewhere in #{geocoder.country}", latitude: latitude, longitude: longitude, address: "Somewhere in #{geocoder.country}", source: Place::UNKNOWN, user_id: current_user.id)
      else
        check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: latitude, longitude: longitude, address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
      end
    end
  end

end
