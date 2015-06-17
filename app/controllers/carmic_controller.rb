class CarmicController < ApplicationController
  def index
    @users =User.where("data -> 'color' != ''").limit(2)
    @hello = "hello there"
    #@users = Place.all

    @hash = Gmaps4rails.build_markers(@users) do |user, marker|
      marker.lat user.last_known_latitude
      marker.lng user.last_known_longitude
      marker.infowindow user.data["plate_number"]

      marker.picture({
                     #url: "https://chart.googleapis.com/chart?chst=d_map_spin&chld=0.8|0|"+user.data["color"]+"|3|",
                     #url: "..//assets/CarMask.png",
                     #"https://chart.googleapis.com/chart?chst=d_map_spin&chld=1|0|"+user.data["color"]+"|5|"
                     url: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=|"+user.data["color"]+"|000000" ,
                     #url: "..//assets/red_car.png",
                     width: 30,
                     height: 80
                 })

    end

    p @hash
    gon.markers = @hash.to_json
    p gon.count = @hash.count

  end


end
