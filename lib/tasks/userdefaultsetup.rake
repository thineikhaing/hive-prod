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
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_bus_stops RESTART IDENTITY")
    result = []
    i = 0
    loop do
      p "result count"
      p result.count
      uri = URI('http://datamall2.mytransport.sg/ltaodataservice/BusStops')
      params = { :$skip => i}
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP::Get.new(uri,
                               initheader = {"accept" =>"application/json",
                                             "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==",
                                             "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
      con = Net::HTTP.new(uri.host, uri.port)
      r = con.start {|http| http.request(res)}
      new_results = JSON.parse(r.body)
      result += new_results["value"]

      # Increment.
      p "increment"
      p i += new_results["value"].count
      p "***"
      break if new_results["value"].count == 0

    end

    uniq_result = result.uniq{ |stop| [stop["BusStopCode"]]}
    uniq_result.each do |data|
      sg = SgBusStop.create(bus_id: data["BusStopCode"].to_s,road_name: data["RoadName"],
                            description: data["Description"],latitude: data["Latitude"],longitude: data["Longitude"])

      puts "#{sg.id}"
    end
  end

  desc "Fetch bus stop data from data mall"
  task :fetch_busroute_data_from_data_mall  => :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_bus_routes RESTART IDENTITY")

    result = []
    i = 0
    loop do
      uri = URI('http://datamall2.mytransport.sg/ltaodataservice/BusRoutes')
      params = { :$skip => i}
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP::Get.new(uri,
                               initheader = {"accept" =>"application/json",
                                             "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==",
                                             "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
      con = Net::HTTP.new(uri.host, uri.port)
      r = con.start {|http| http.request(res)}
      new_results = JSON.parse(r.body)
      result += new_results["value"]

      # Increment.
      p "increment"
      p i += new_results["value"].count
      p "***"
      break if new_results["value"].count == 0
    end

    uniqresults = result.uniq do |hash|
      [hash["ServiceNo"],hash["BusStopCode"] ,hash["StopSequence"]]
    end
    uniqresults.each do |data|

      rt = SgBusRoute.create(service_no: data["ServiceNo"],operator: data["Operator"],
                             direction: data["Direction"],stop_sequence: data["StopSequence"],
                             bus_stop_code: data["BusStopCode"],distance: data["Distance"],
                             wd_firstbus: data["WD_FirstBus"],wd_lastbus: data["WD_LastBus"],
                             sat_firstbus: data["SAT_FirstBus"],sat_lastbus: data["SAT_LastBus"],
                             sun_firstbus: data["SUN_FirstBus"],sun_lastbus: data["SUN_LastBus"])
      puts "#{rt.id}"

    end
  end


  desc "Fetch bus service data from data mall"
  task :fetch_busservice_data_from_data_mall  => :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_bus_services RESTART IDENTITY")

    result = []
    i = 0
    loop do
      p "result count"
      p result.count

      uri = URI('http://datamall2.mytransport.sg/ltaodataservice/BusServices')
      params = { :$skip => i}
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP::Get.new(uri,
                               initheader = {"accept" =>"application/json",
                                             "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==",
                                             "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
      con = Net::HTTP.new(uri.host, uri.port)
      r = con.start {|http| http.request(res)}
      new_results = JSON.parse(r.body)
      result += new_results["value"]

      # Increment.
      p "increment"
      p i += new_results["value"].count
      p "***"
      break if new_results["value"].count == 0

    end

    uniqresults = result.uniq{ |service| [service["ServiceNo"], service["Direction"]]}
    uniqresults.each do |data|

      scv = SgBusService.create(service_no: data["ServiceNo"],operator: data["Operator"],
                          direction: data["Direction"],category: data["Category"],
                          origin_code: data["OriginCode"],destination_code: data["DestinationCode"],
                          am_peak_freq: data["AM_Peak_Freq"],am_offpeak_freq: data["AM_Offpeak_Freq"],
                          pm_peak_freq: data["PM_Peak_Freq"],pm_offpeak_freq: data["PM_Offpeak_Freq"])
      puts "#{scv.id}"
      puts "#{scv.service_no}"
      puts "***"
    end
  end

  desc "simulate multiple chat conversation"
  task :simulate_multiple_users_chatting  => :environment do
    # scheduler = Rufus::Scheduler.new
    # job = scheduler.every '15s' do
      users = User.all.sample(15)
      topic = Topic.find_by(topic_sub_type: 2)
      users.each do |u|
        post = Post.create(content:LiterateRandomizer.sentence,
                           post_type: 3,
                           topic_id: topic.id,
                           user_id: u.id,
                           place_id: 0)
         post.broadcast_hive
         post.broadcast_other_app(nil)
       end
  end

  desc "fetch ygn bus stops"
  task :fetch_ygn_bus_stops  => :environment do
    uri = URI('http://ygnbus.herokuapp.com/api/bus/')
    res = Net::HTTP::Get.new(uri, initheader = {"Authorization" =>"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoiMzc2ODcyOTMiLCJoYXNoIjp7Il9oYW5kbGUiOnt9fX0.Hl5u9m4n5npnLpRBehyFMrbghMlOYeMT1xUru3bIXVQ"})
    con = Net::HTTP.new(uri.host, uri.port)
    r = con.start {|http| http.request(res)}
    results = JSON.parse(r.body)
    results.map{|data|
      p data["bus"]["busID"]
      p data["bus"]["busName"]
      p data["bus"]["busTypeID"]["busTypeName"]
      p "++++++++++++++++"
    }
    end


end
