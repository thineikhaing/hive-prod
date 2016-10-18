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

    if Rails.env.development?
      round_key = RoundTrip_key::Staging_Key
    elsif Rails.env.staging?
      round_key = RoundTrip_key::Staging_Key
    else
      round_key = RoundTrip_key::Production_Key
    end

    hive = HiveApplication.find(hive_id)


    radius = 1 if radius.nil?
    center_point = [latitude.to_f, longitude.to_f]
    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
    places = Place.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])

    topics_array = [ ]

    if hive.api_key == round_key

      places.each do |place|
        if place.start_places.present?
          place.start_places.each do |topic|
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

      places.each do |place|
        if place.end_places.present?
          place.end_places.each do |topic|
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

    else
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

    end


    if topics_array.present?
      p "uniq array"
      topics_array = topics_array.uniq{ |topic| [topic["id"]]}
    else
      topics_array = [ ]
    end
    topics_array
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
    s_places = Place.where(latitude: s_box[0] .. s_box[2], longitude: s_box[1] .. s_box[3])

    e_center_point = [e_latitude.to_f, e_longitude.to_f]
    e_box = Geocoder::Calculations.bounding_box(e_center_point, radius, {units: :km})
    e_places = Place.where(latitude: e_box[0] .. e_box[2], longitude: e_box[1] .. e_box[3])

    topics_array = [ ]

    s_places.each do |place|
      if place.start_places.present?
        (topics_array << place.start_places).flatten!
      end

      if place.end_places.present?
        # topics_array.merge(place.end_places)
        (topics_array << place.end_places).flatten!
      end

    end

    e_places.each do |place|
      if place.start_places.present?
        (topics_array << place.start_places).flatten!
      end

      if place.end_places.present?
        (topics_array << place.end_places).flatten!
      end
    end


    if radius_between >= 4
      p "get the center point's topic list cuz radius is greater than 4 km"
      p radius_between
      p centerpoint
      center_box = Geocoder::Calculations.bounding_box(centerpoint, radius, {units: :km})
      center_places = Place.where(latitude: center_box[0] .. center_box[2], longitude: center_box[1] .. center_box[3])

      center_places.each do |place|
        if place.start_places.present?
          (topics_array << place.start_places).flatten!
        end

        if place.end_places.present?
          (topics_array << place.end_places).flatten!
        end

      end
    end
    #

    if topics_array.present?
      topics_array = topics_array.uniq{ |topic| [topic[:id]]}
    else
      topics_array = [ ]
    end
    # modify_topic = []
    # topics_array.each do |topic|
    #   p s_id = topic.rtplaces_information[:start_place][:id]
    #   p e_id = topic.rtplaces_information[:end_place][:id]
    #   s_fav = UserFavLocation.where(user_id: current_user.id, place_id: s_id).take
    #   e_fav = UserFavLocation.where(user_id: current_user.id, place_id: e_id).take
    #
    #   topic.rtplaces_information[:start_place][:name] = s_fav.name if s_fav.present?
    #   topic.rtplaces_information[:end_place][:name] = e_fav.name if e_fav.present?
    #
    # end


    # a.sort {|x,y| y[:bar]<=>x[:bar]}
    #     topics_array.sort_by { |k| k["id"] }


    # p topics_array.count rescue '0'

  end

  # add_record("name", "latitude", "longitude", "address", "", "", 163, 333, "y-cZXxwrSXvtiyTGBzpf", "choice","img_url",category="",locality="",country="",postcode="")

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
        p "exciting record"
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
        place = ""
        check_records = Place.where(name:@spot.name, source:7)

        check_records.each do |cr|
          p "exisiting google record"
          place = cr if cr.name.downcase == @spot.name.downcase
        end
        if place == ""
          place = Place.create(
              name: @spot.name,
              latitude: @spot.lat,
              longitude: @spot.lng,
              address: @spot.formatted_address,
              source: Place::GOOGLE,
              source_id: source_id,
              user_id: user_id,
              img_url: url,
              category: category,
              country: @spot.country,
              postal_code: @spot.postal_code,
              locality: locality)
        end


        p "place source id"
        p place
        p place.source_id
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
        place = ""
        private_place = ""
        check_records = Place.nearest(latitude, longitude, 0.5)

        check_records.each do |cr|

          private_place = cr if cr.user_id == user_id and cr.source == 6
          place = cr if cr.name.downcase == name.downcase if name.present?
        end

        p "check place "
        p place

        if private_place.present?
          return { place: private_place, status: 71 }
        else
          if choice == "luncheon"
            place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, category: "Food and Dining",img_url: img_url,country: country,postal_code: postcode,locality: locality) unless place.present?
          else

            geocoder = Geocoder.search("#{latitude},#{longitude}").first
            if geocoder.present? and geocoder.address.present?
              check = Place.find_by_address(geocoder.address)
              check.present? ? place = check : place = Place.create(name: geocoder.address, latitude: latitude, longitude: longitude,
                  address: geocoder.address, source: source, source_id: source_id, user_id: user_id,
                  img_url: img_url,category: category,country: geocoder.country,
                  postal_code: geocoder.postal_code,locality: locality) unless place.present?
            end

            # if name.present?
            #   place = Place.create(name: name, latitude: latitude, longitude: longitude, address: address, source: source, user_id: user_id, img_url: img_url,category: category,country: country,postal_code: postcode,locality: locality) unless place.present?
            # else
            #   geocoder = Geocoder.search("#{latitude},#{longitude}").first
            #   if geocoder.present? and geocoder.address.present?
            #     check = Place.find_by_address(geocoder.address)
            #     check.present? ? place = check : place = Place.create(name: geocoder.address, latitude: latitude, longitude: longitude,
            #                                                           address: geocoder.address, source: source, source_id: source_id, user_id: user_id,
            #                                                           img_url: img_url,category: category,country: geocoder.country,
            #                                                           postal_code: geocoder.postal_code,locality: locality) unless place.present?
            #   end
            # end
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
    # geocoder = Geocoder.search("1.3326774, 103.8474212").first
    geocoder = Geocoder.search("#{latitude},#{longitude}").first

    geocoder = Geocoder.search("1.31762812403745,103.849500944488").first

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
