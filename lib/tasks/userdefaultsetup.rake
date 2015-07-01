namespace :userdefaultsetup do

  desc "import system data"
  task :import_countries => :environment do
    
   countries_json = JSON.parse(File.read("db/countries.json"));
    #Delete all previous records
    # Country.delete_all
   DatabaseCleaner.clean_with(:truncation, :only => ['countries'])
    countries_json.each do |country|
              c = Country.new(country)
              c.save
    end

    puts "Countries created"
  end

    
end