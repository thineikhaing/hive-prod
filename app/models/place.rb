class Place < ActiveRecord::Base
  has_many :topics
  has_many :user_fav_locations
  belongs_to :user

  has_many :start_places , class_name: "Topic", foreign_key: "start_place_id",primary_key: :id
  has_many :end_places , class_name: "Topic", foreign_key: "end_place_id",primary_key: :id

  # Setup hstore
  store_accessor :data

  #attr_accessible :name, :category, :address, :locality, :region, :neighbourhood, :chain_name, :country, :postal_code, :website_url, :contact_number, :img_url, :source, :source_id, :latitude, :longitude, :user_id

  enums %w(HERENOW USER VENDOR FACTUAL MRT UNKNOWN PRIVATE GOOGLE GOTHERE)

  # def self.start_places
  #   Topic.where(start_place_id: self.id)
  # end
  #
  # def self.end_places
  #   Topic.where(end_place_id: self.id)
  # end



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


  # Returns nearest topics within n latitude, n longitude and n radius (For downloaddata controller)
  def self.nearest_topics_within_start_and_end(s_latitude, s_longitude,e_latitude, e_longitude, radius, hive_id)


    topics_array = [ ]
    p "radius between two points"
    p radius_between = Geocoder::Calculations.distance_between([s_latitude,s_longitude], [e_latitude,e_longitude], {units: :km})
    radius_between = radius_between.ceil

    center_points = Geocoder::Calculations.geographic_center([[s_latitude, s_longitude], [e_latitude, e_longitude]])

    end_center_points = Geocoder::Calculations.geographic_center([center_points, [e_latitude, e_longitude]])

    start_center_points = Geocoder::Calculations.geographic_center([[s_latitude, s_longitude], center_points])

    radius = ((radius_between * 0.5) * 0.5).ceil

    radius = (radius * 0.5).ceil

    s_sc = Geocoder::Calculations.geographic_center([[s_latitude, s_longitude], start_center_points])
    sc_cp = Geocoder::Calculations.geographic_center([start_center_points, center_points])

    cp_ec = Geocoder::Calculations.geographic_center([center_points, end_center_points])
    ec_e = Geocoder::Calculations.geographic_center([end_center_points, [e_latitude, e_longitude]])


    s_sc_box = Geocoder::Calculations.bounding_box(s_sc, radius, {units: :km})
    s_sc_places = Place.where(latitude: s_sc_box[0] .. s_sc_box[2], longitude: s_sc_box[1] .. s_sc_box[3])

    sc_cp_box = Geocoder::Calculations.bounding_box(sc_cp, radius, {units: :km})
    sc_cp_places = Place.where(latitude: sc_cp_box[0] .. sc_cp_box[2], longitude: sc_cp_box[1] .. sc_cp_box[3])

    cp_ec_box = Geocoder::Calculations.bounding_box(cp_ec, radius, {units: :km})
    cp_ec_places = Place.where(latitude: cp_ec_box[0] .. cp_ec_box[2], longitude: cp_ec_box[1] .. cp_ec_box[3])

    ec_e_box = Geocoder::Calculations.bounding_box(ec_e, radius, {units: :km})
    ec_e_places = Place.where(latitude: ec_e_box[0] .. ec_e_box[2], longitude: ec_e_box[1] .. ec_e_box[3])


    s_sc_places.each do |place|
      if place.start_places.present?
        place.start_places.each do |topic|
          topics_array.push(topic)
        end
      end
    end

    sc_cp_places.each do |place|
      if place.start_places.present?
        place.start_places.each do |topic|
          topics_array.push(topic)
        end
      end
    end

    cp_ec_places.each do |place|
      if place.end_places.present?
        place.end_places.each do |topic|
          topics_array.push(topic)
        end
      end
    end

    ec_e_places.each do |place|
      if place.end_places.present?
        place.end_places.each do |topic|
          topics_array.push(topic)
        end
      end
    end


    # topics_array.each do |t|
    #   p t.title
    #   p t.start_place.name rescue '++'
    #   p t.end_place.name rescue '++'
    # end

    topics_array

  end

  # add_record("name", "latitude", "longitude", "address", "", "", 163, 333, "y-cZXxwrSXvtiyTGBzpf", "choice","img_url",category="",locality="",country="",postcode="")

  def add_record(name, latitude, longitude, address, source, source_id, place_id, user_id, auth_token, choice,img_url,category="",locality="",country="",postcode="")
    factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    user = User.find(user_id)

    p user.username
    p source
    p source_id
    p place_id
    p "++++"

    neighborhood = ""
    website = ""
    tel = ""
    category = "" unless category.present?
    if auth_token.present?
      if place_id.present?
        p "exciting record"
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
      elsif source_id.present? && source.to_i == Place::GOTHERE

        check_record = Place.find_by_postal_code(source_id)

        if check_record.present?
          place = check_record
        else

          response = Net::HTTP.get_response(URI("https://gothere.sg/maps/geo?output=&q='#{source_id}'&client=&sensor=false&callback=")).body
          response = JSON.parse(response)
          status = response["Status"]["code"]
          if status == 200
            place= response["Placemark"][0]
            add_detail = place["AddressDetails"]["Country"]

            lng  = place["Point"]["coordinates"][0]
            lat= place["Point"]["coordinates"][1]

            name = add_detail["Thoroughfare"]["ThoroughfareName"]
            country_name = add_detail["Thoroughfare"]["CountryName"]
            add = place["address"]

            place = Place.create(name: name, latitude: lat, longitude: lng, address: add, country: country_name,
                                 category: category, locality: locality, postal_code: source_id,
                                 source: Place::GOTHERE, source_id: source_id, user_id: user_id,img_url: img_url)
          end

        end

        return { place: place, status: 70 }

      elsif source_id.present? && source.to_i == Place::FACTUAL
        p "add record from factual"
        factual_result = factual.table("places").filters("factual_id" => source_id.to_s).first
        p factual_result
        if factual_result["category_labels"].present?
          p factual_result["category_labels"]

          category_labels = factual_result["category_labels"]
          category_labels.each do |fr|
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
              category.present? ? category << "," << fr.to_s : category << fr.first.to_s
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

      elsif source_id.present? && source.to_i == Place::GOOGLE
        p "add record from google"
        @client = GooglePlaces::Client.new(GoogleAPI::Google_Key)
        @spot = @client.spot(source_id.to_s)

        url = ""

        if img_url.present?
          url = img_url
        else

          if @spot.photos[0].present?
            url = @spot.photos[0].fetch_url(800)
          else
            url = ""
          end

        end


        place = Place.create(name: @spot.name, latitude: @spot.lat, longitude: @spot.lng, address: @spot.formatted_address, source: Place::GOOGLE, user_id: user_id, img_url: url,category: category,country: @spot.country,postal_code: @spot.postal_code,locality: locality) unless place.present?

        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        user.check_in_time = Time.now
        user.save!
        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }

      else
        p "add user custom record"
        place = ""
        private_place = ""
        check_records = Place.nearest(latitude, longitude, 0.5)

        check_records.each do |cr|
          p "name ::::"
          p cr
          private_place = cr if cr.user_id == user_id and cr.source == 6
          place = cr if cr.name.downcase == name.downcase if name.present?
        end


        if private_place.present?
          return { place: private_place, status: 71 }
        else
          if choice == "luncheon"
            place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, category: "Food and Dining",img_url: img_url,country: country,postal_code: postcode,locality: locality) unless place.present?
          else

            if name.present?
              place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, img_url: img_url,category: category,country: country,postal_code: postcode,locality: locality) unless place.present?
            else
              geocoder = Geocoder.search("#{latitude},#{longitude}").first
              if geocoder.present? and geocoder.address.present?
                check = Place.find_by_address(geocoder.address)
                check.present? ? place = check : place = Place.create(name: geocoder.address, latitude: latitude, longitude: longitude,
                                                                      address: geocoder.address, source: source, user_id: user_id,
                                                                      img_url: img_url,category: category,country: geocoder.country,
                                                                      postal_code: geocoder.postal_code,locality: locality) unless place.present?
              end
            end



            #
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
    # factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    # query = factual.geo(latitude,longitude).first
    #
    # if query.present?
    #   if query["address"].present?
    #     check = Place.find_by_address(query["address"])
    #     check.present? ? place = check : place = Place.create(name: query["address"], latitude:latitude, longitude: longitude, address: query["address"], postal_code: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
    #   elsif query["locality"].present?
    #     check = Place.find_by_address("Somewhere in #{query["locality"]}")
    #     check.present? ? place = check : place = Place.create(name: "Somewhere in #{query["locality"]}", latitude: latitude, longitude: longitude, address: "Somewhere in #{query["locality"]}", postal_code: query["postcode"], locality: query["locality"], country: query["country"], source: Place::UNKNOWN, user_id: current_user.id)
    #   end
    # else
    #   geocoder = Geocoder.search("#{latitude},#{longitude}").first
    #
    #
    #
    #   if geocoder.present? and geocoder.address.present?
    #     check = Place.find_by_address(geocoder.address)
    #     check2 = Place.find_by_address("Somewhere in the world")
    #
    #     check.present? ? place = check : place = Place.create(name: geocoder.address, latitude: latitude, longitude: longitude,
    #                                                           address: geocoder.address,country: geocoder.country,
    #                                                           source: Place::UNKNOWN, user_id: current_user.id,postal_code: geocoder.postal_code)
    #   else
    #     check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: latitude, longitude: longitude, address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
    #   end
    #
    #
    # end

    geocoder = Geocoder.search("#{latitude},#{longitude}").first

    if geocoder.present? and geocoder.address.present?
      check = Place.find_by_address(geocoder.address)
      check2 = Place.find_by_address("Somewhere in the world")

      check.present? ? place = check : place = Place.create(name: geocoder.address, latitude: latitude, longitude: longitude,
                                                            address: geocoder.address,country: geocoder.country,
                                                           source: Place::UNKNOWN, user_id: current_user.id,postal_code: geocoder.postal_code)
    else
      check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: latitude, longitude: longitude, address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
    end

  end

end
