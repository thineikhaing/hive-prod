class CarmicController < ApplicationController
  def index
    @users =User.where("data -> 'color' != ''")

    @hash = Gmaps4rails.build_markers(@users) do |user, marker|

      content = '<p class="hook">'+user.data["plate_number"]+'</p>'

      marker.lat user.last_known_latitude
      marker.lng user.last_known_longitude
      marker.infowindow content

      marker.picture({
                     #url: "..//assets/CarMask.png#"+user.data["color"],
                     #url: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=|"+user.data["color"]+"|000000" ,
                     url: "..//assets/red_car.png#red",
                     width: 33,
                     height: 80
                 })

      marker.json({custom_marker: "<div style='background:#"+user.data["color"]+";width:33;height:80'><img src='#{"..//assets/CarMask.png"}'></div>"
                  })

    end
    if Rails.env.development?
      @url = "http://localhost:5000/api/downloaddata/retrieve_carmic_user"

    elsif Rails.env.staging?
      @url = "http://h1ve-staging.herokuapp.com/api/downloaddata/retrieve_carmic_user"
    else
      @url = "http://h1ve-production.herokuapp.com/api/downloaddata/retrieve_carmic_user"
    end


  end

  def gmaps4rails_marker_picture
    {
        "rich_marker" =>  "<div class='my-marker'>It works!<img height='30' width='30' src='http://farm4.static.flickr.com/3212/3012579547_097e27ced9_m.jpg'/></div>"
    }
  end


end
