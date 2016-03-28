class Api::RoundtripController < ApplicationController
  require 'google_maps_service'

  def routetest
# Setup API keys
    gmaps = GoogleMapsService::Client.new(key: GoogleAPI::Google_Key)

    # Simple directions
    p routes = gmaps.directions(
        'Changi Airport Singapore, Airport Boulevard',
        'novena',
        mode: 'transit',
        alternatives: true)

    p routes["routes"].first["legs"].arrival_time["text"]
    p routes["routes"].first["legs"].arrival_time["text"]

    render json: {routes: routes}
  end


end
