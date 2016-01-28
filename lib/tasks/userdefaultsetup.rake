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
    DatabaseCleaner.clean_with(:truncation, :only => ['lookups'])
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

    
end