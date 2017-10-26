namespace :userdefaultsetup do

  desc "import system data"
  task :import_countries => :environment do
    
   countries_json = JSON.parse(File.read("db/countries.json"));
    #Delete all previous records
    # Country.delete_all
   #DatabaseCleaner.clean_with(:truncation, :only => ['countries'])

   countries_json.each do |country|
              c = Country.new(country)
              c.save
    end

    puts "Countries created"
  end

  desc "add role to admin dev user"
  task :add_role_to_devadmin => :environment do

    user = Devuser.find_by_username('Hive Admin')
    user.email = "devs@herenow.io"
    user.password = "5198278387438044"
    user.role = 1
    user.save

    puts "Admin dev user role and info updated!"
  end

  desc "Import Lookup DDM"
  task :import_lookup_data => :environment do
    lookups_json = JSON.parse(File.read("db/lookups.json"));
    #Delete all previous records
    # Lookup.delete_all
    # DatabaseCleaner.clean_with(:truncation, :only => ['lookups'])
    lookups_json.each do |lookup|
      #puts state
      new_lookup = Lookup.new
      new_lookup.name = lookup["name"]
      new_lookup.value = lookup["value"]
      new_lookup.lookup_type = lookup["type"]
      new_lookup.save
    end
    puts "Lookup DDMs created!"
  end


  # CSV.foreach("db/migrate/20140328083723_stations_seed.csv") do |row|
  #   Place.create(name: row[0], latitude: row[1], longitude: row[2], address: row[3], locality: row[4], country: row[5], img_url: row[6], user_id: admin.id, source: 0)
  #   puts "Created: #{row}"
  # end

  desc "Update MRT latitude and longitude"
  task :update_mrt_lat_and_lng => :environment do
    CSV.foreach("db/stations_seed.csv") do |row|
      place = Place.find_by_name(row[0])
      place.latitude =  row[1]
      place.longitude = row[2]
      place.save
    end
  end


  desc "Add short name for place table"
  task :add_shortname_to_place => :environment do
    @client = GooglePlaces::Client.new(GoogleAPI::Google_Key)

    places = Place.all
    places.each do |p|
      geocoder = Geocoder.search("#{p.latitude},#{p.longitude}").first
      if geocoder.present?
        place = @client.spot(geocoder.place_id)
        place.present? ? street = place.street : street = ""
        short_name = street
      else
        short_name = ""
      end
      p.short_name = short_name
      p.save
    end
  end

  desc "Fetch bus stop data from data mall"
  task :fetch_busstop_data_from_data_mall  => :environment do
    # DatabaseCleaner.clean_with(:truncation, :only => ['sg_bus_stops'])

    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_bus_stops RESTART IDENTITY")
    result = []
    i = 0
    while i < 5300

      p "result count"
      p result.count

      uri = URI('http://datamall2.mytransport.sg/ltaodataservice/BusStops')
      params = { :$skip => i}
      uri.query = URI.encode_www_form(params)
      p uri
      res = Net::HTTP::Get.new(uri,
                               initheader = {"accept" =>"application/json",
                                             "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==",
                                             "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
      con = Net::HTTP.new(uri.host, uri.port)
      r = con.start {|http| http.request(res)}
      new_results = JSON.parse(r.body)

      p new_results["value"].last
      p "+++++++++"

      result += new_results["value"]

      p "new_results"
      p new_results["value"].count

      # Increment.
      i += 50
    end


    result.each do |data|
      SgBusStop.create(bus_id: data["BusStopCode"],road_name: data["RoadName"],
          description: data["Description"],latitude: data["Latitude"],longitude: data["Longitude"])

    end

  end





end