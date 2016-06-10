class TaxiAvailability < ActiveRecord::Base
  require 'uri'
  require 'net/http'


  def self.fetch_nearby_taxi

    t=Time.now
    t= t.strftime("%Y-%m-%dT%H:%M%S")
    full_path = 'https://api.data.gov.sg/v1/transport/taxi-availability?date_time='+t
    url = URI.parse(full_path)
    req = Net::HTTP::Get.new(url.path, initheader = {"accept" =>"application/json",  "api-key"=>"PGif1D2lFvYZCxLeAodZtdAAuEIleWkG"})
    con = Net::HTTP.new(url.host, url.port)
    con.use_ssl = true

    p "request"
    p req
    r = con.start {|http| http.request(req)}
    p "get taxi list"

    @request_payload = JSON.parse r.body
    @request_payload["features"].each do |data|
      p "get data"

      ActiveRecord::Base.connection.execute("TRUNCATE TABLE taxi_availabilities
 RESTART IDENTITY")

      data["geometry"]["coordinates"].each do |coor|
        x = coor[1]
        y = coor[0]
        taxi = TaxiAvailability.new(latitude: x, longitude: y, date_time: Time.now)
        taxi.save

      end

    end

  end

end



