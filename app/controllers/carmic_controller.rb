class CarmicController < ApplicationController
  def index
    @users =User.where("data -> 'color' != ''")

    @topics= Topic.where(hiveapplication_id: 3)

    @hash = Gmaps4rails.build_markers(@users) do |user, marker|

      content = '<p class="hook">'+user.data["plate_number"]+'</p>'

      marker.lat user.last_known_latitude
      marker.lng user.last_known_longitude
      marker.infowindow user.data["plate_number"]

      marker.picture({
                     url: "..//assets/red_car.png#red",
                     width: 33,
                     height: 80
                 })

      marker.json({custom_marker: "<div class='marker_icon' style='background:#"+user.data["color"]+";width:33;height:80'><img src='#{"..//assets/CarMask.png"}'></div>",
                   marker_id: user.id
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

end
