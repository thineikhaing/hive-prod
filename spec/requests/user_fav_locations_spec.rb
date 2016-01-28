require 'rails_helper'

RSpec.describe "UserFavLocations", type: :request do
  describe "GET /user_fav_locations" do
    it "works! (now write some real specs)" do
      get user_fav_locations_path
      expect(response).to have_http_status(200)
    end
  end
end
