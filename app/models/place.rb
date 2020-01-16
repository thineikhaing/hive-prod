class Place < ActiveRecord::Base
  has_many :topics
  has_many :user_fav_locations
  belongs_to :user
  has_many :start_topics , class_name: "Topic", foreign_key: "start_place_id",primary_key: :id
  has_many :end_topics , class_name: "Topic", foreign_key: "end_place_id",primary_key: :id
  # Setup hstore
  store_accessor :data
  enums %w(HERENOW USER VENDOR FACTUAL MRT UNKNOWN PRIVATE GOOGLE GOTHERE ONEMAP)

  # Returns nearest topics within n latitude, n longitude and n radius (For downloaddata controller)
  def self.nearest_topics_within(latitude, longitude, radius, hive_id)

    if Rails.env.development?
      round_key = RoundTrip_key::Staging_Key
    elsif Rails.env.staging?
      round_key = RoundTrip_key::Staging_Key
    else
      round_key = RoundTrip_key::Production_Key
    end
    hive = HiveApplication.find(hive_id)
    radius = 1 if radius.nil?
    radius = 0.5
    center_point = [latitude.to_f, longitude.to_f]

    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})

    places = Place.joins(:start_topics).joins(:end_topics).where(latitude: box[0] .. box[2], longitude: box[1] .. box[3]).distinct
    topicPlaces = Place.joins(:topics).where(latitude: box[0] .. box[2], longitude: box[1] .. box[3]).distinct

    topics_array = [ ]
    if hive.api_key == round_key
      places.each do |place|
        (topics_array << place.start_topics.order("created_at asc")).flatten! if place.start_topics.present?
        (topics_array << place.end_topics.order("created_at asc")).flatten!  if place.end_topics.present?
      end

      topicPlaces.each do |place|
        (topics_array << place.topics.order("created_at asc")).flatten! if place.topics.present?
      end
    else
      places.each do |place|
        if place.topics.present?
          topic_places = place.topics.order("created_at asc")
          topic_places.each do |topic|
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
    end

    if topics_array.present?
      topics_array = topics_array.uniq{ |topic| [topic["id"]]}
    else
      topics_array = [ ]
    end

  end


  # Returns nearest topics within n latitude, n longitude and n radius (For downloaddata controller)
  def self.nearest_topics_within_start_and_end(s_latitude, s_longitude,e_latitude, e_longitude, radius, hive_id)

    radius = 1
    radius_between = Geocoder::Calculations.distance_between([s_latitude,s_longitude], [e_latitude,e_longitude], {units: :km})
    radius_between = radius_between.round

    p "radius between two points is #{radius_between} km"

    if radius_between < 2 and radius_between > 0
      radius = (radius_between * 0.5).round(2)
      p "radius between o..2"
    elsif radius_between >= 2
      p "radius greater than equal 2 "
      radius = 1
    else
      p "radius is less than zero"
      radius = 1
    end
    p "radius to query"
    p radius
    p "topic list within #{radius}km of each points"

    centerpoint = Geocoder::Calculations.geographic_center([[s_latitude, s_longitude], [e_latitude,e_longitude]])

    s_center_point = [s_latitude.to_f, s_longitude.to_f]
    s_box = Geocoder::Calculations.bounding_box(s_center_point, radius, {units: :km})
    s_places = Place.where(latitude: s_box[0] .. s_box[2], longitude: s_box[1] .. s_box[3]).distinct

    e_center_point = [e_latitude.to_f, e_longitude.to_f]
    e_box = Geocoder::Calculations.bounding_box(e_center_point, radius, {units: :km})
    e_places = Place.where(latitude: e_box[0] .. e_box[2], longitude: e_box[1] .. e_box[3]).distinct

    topics_array = [ ]

    e_places.each do |place|
      (topics_array << place.start_topics.order("created_at asc")).flatten! if place.start_topics.present?
      (topics_array << place.end_topics.order("created_at asc")).flatten! if place.end_topics.present?
      (topics_array << place.topics.order("created_at asc")).flatten! if place.topics.present?
    end

    s_places.each do |place|
      (topics_array << place.start_topics.order("created_at asc")).flatten! if place.start_topics.present?
      (topics_array << place.end_topics.order("created_at asc")).flatten! if place.end_topics.present?
      (topics_array << place.topics.order("created_at asc")).flatten! if place.topics.present?
    end


    if radius_between >= 4
      p "get the center point's topic list cuz radius is greater than 4 km"
      p radius_between
      p centerpoint
      center_box = Geocoder::Calculations.bounding_box(centerpoint, radius, {units: :km})
      center_places = Place.joins(:topics).where(latitude: center_box[0] .. center_box[2], longitude: center_box[1] .. center_box[3]).distinct
      center_places.each do |place|
        (topics_array << place.start_topics.order("created_at asc")).flatten! if place.start_topics.present?
        (topics_array << place.end_topics.order("created_at asc")).flatten! if place.end_topics.present?
      end
    end

    if topics_array.present?
      topics_array = topics_array.uniq{ |topic| [topic[:id]]}
    else
      topics_array = [ ]
    end
  end

  def add_record(name, latitude, longitude, address, source, source_id, place_id, user_id, auth_token,
                 choice,img_url,category="",locality="",country="",postcode="")
    factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
    user = User.find(user_id)

    neighborhood = ""
    website = ""
    tel = ""
    category = "" unless category.present?
    if auth_token.present?
      if place_id.present?
        p "place id exit"
        place = Place.find(place_id)
        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        user.check_in_time = Time.now
        user.save!

        place.img_url = img_url if img_url.present?
        place.locality = locality if locality.present?
        place.country = country if country.present?
        place.postcode = postcode if postcode.present?
        place.save!

        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }

      elsif source.to_i == Place::ONEMAP
        place = ""
        check_records = Place.where(address:address)

        check_records.each do |cr|
          p "exisiting  record"
          place = cr if cr.address.downcase == address.downcase
        end

        if address.nil?
          address = name
        end

        if place == ""
          place = Place.create(
              name: name,
              latitude: latitude,
              longitude: longitude,
              address: address,
              source: 9,
              source_id: source_id,
              user_id: user_id,
              img_url: img_url,
              category: category,
              country: country,
              postal_code: postcode,
              locality: locality)
        end


        p "place***"
        p place
        place.save!

        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        user.check_in_time = Time.now
        user.save!
        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }

      elsif source.to_i == Place::GOTHERE

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

      elsif source.to_i == Place::FACTUAL
        p "add record from factual"

        factual_result = factual.table("places").filters("factual_id" => "2e8e4a1a-3838-48a4-b8ed-f6d9c717a715").first
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


        place = ""
        p check_records = Place.where(name:factual_result["name"], source:3)
        p "check record"

        check_records.each do |cr|
          p "exisiting factual record"
          place = cr if cr.name.downcase == factual_result["name"].downcase
        end

        if place == ""
          place = Place.create(name: factual_result["name"], latitude: factual_result["latitude"], longitude: factual_result["longitude"], address: factual_result["address"],
              country: factual_result["country"], category: category, locality: factual_result["locality"], postal_code: factual_result["postcode"], region: factual_result["region"],
              website_url: website, source: 3, source_id: source_id, user_id: user_id,img_url: img_url)
        end

        #end
        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        user.check_in_time = Time.now
        user.save!
        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }

      elsif source.to_i == Place::GOOGLE
        p "add record from google"
        @client = GooglePlaces::Client.new(GoogleAPI::Google_Key)

        url = ""
        if img_url.present?
          url = img_url
        elsif source_id.present?
            p "+++ source id +++"
            p source_id
            @spot = @client.spot(source_id.to_s)
            url = @spot.photos[0].fetch_url(800) if @spot.photos[0].present?
        end

        place = ""

        check_records = Place.where(name:name,source:7)

        check_records.each do |cr|
          p "exisiting google record"
          place = cr if cr.address.downcase == address.downcase if address.present?
        end

        if place == ""
          place = Place.create(
              name: name,
              latitude:latitude,
              longitude:longitude,
              address: address,
              source: Place::GOOGLE,
              source_id: source_id,
              user_id: user_id,
              img_url: url,
              category: category,
              country: country,
              postal_code: postcode,
              locality: locality)
        end

        place.save!

        Checkinplace.create(place_id: place.id, user_id: user_id)
        user.last_known_latitude =  place.latitude
        user.last_known_longitude = place.longitude
        user.check_in_time = Time.now
        user.save!
        Userpreviouslocation.create(latitude: place.latitude, longitude: place.longitude, radius: 1, user_id: user_id)

        return { place: place, status: 70 }

      else
        p "add user custom record"
        p address
        place = ""
        private_place = ""
        check_records = Place.nearest(latitude, longitude, 0.5)

        check_records.each do |cr|
          private_place = cr if cr.user_id == user_id and cr.source == 6
          if cr.name.present?
           place = cr if cr.address.downcase == address.downcase if address.present?
          end
        end


        if private_place.present?
          return { place: private_place, status: 71 }
        else
          if choice == "luncheon"
            place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, category: "Food and Dining",img_url: img_url,country: country,postal_code: postcode,locality: locality) unless place.present?
          else

            if place.blank?
              geocoder = Geocoder.search("#{latitude},#{longitude}").first
              p "geocoder.address"
              p geocoder
              p geocoder.display_name
              p geocoder.address

              if geocoder.present? and geocoder.display_name.present?
                !name.blank? ? name = name : name = geocoder.data["address"]["road"]
                !address.nil? ? address = address : address = geocoder.address
                if address.present?
                  check = Place.find_by_address(address)
                else
                  check = Place.find_by_address(geocoder.address)
                end

                check.present? ? place = check : place = Place.create(name: name, latitude: latitude, longitude: longitude,
                    address: address, source: source, source_id: source_id, user_id: user_id,
                    img_url: img_url,category: category,country: geocoder.country,
                    postal_code: geocoder.postal_code,locality: locality) unless place.present?
              end

            end

          end


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
        new_place = Place.create(name: factual_result["name"], latitude: factual_result["latitude"],
            longitude: factual_result["longitude"], address: factual_result["address"],
            country: factual_result["country"], category: category, locality: factual_result["locality"],
            postal_code: factual_result["postcode"], region: factual_result["region"],  website_url: website,
            source: 3,source_id: source_id, user_id: user_id,img_url: img_url)

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

    geocoder = Geocoder.search("#{latitude},#{longitude}").first
    p "Place GEO lat|lng"
    if geocoder.present? and geocoder.address.present?
      check = Place.find_by_address(geocoder.address)
      check2 = Place.find_by_address("Somewhere in the world")
      check.present? ? place = check : place = Place.create(name: geocoder.data["address"]["road"], latitude: latitude, longitude: longitude,
                                                            address: geocoder.address,country: geocoder.country,
                                                           source: Place::UNKNOWN, user_id: current_user.id,postal_code: geocoder.postal_code)
    else
      check2.present? ? place = check2 : place = Place.create(name: "Somewhere in the world", latitude: latitude, longitude: longitude, address: "Somewhere in the world", source: Place::UNKNOWN, user_id: current_user.id)
    end

  end

end
