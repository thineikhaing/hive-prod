require 'rails_helper'

RSpec.describe "RouteLogs", type: :request do
  describe "GET /route_logs" do
    it "works! (now write some real specs)" do
      get route_logs_path
      expect(response).to have_http_status(200)
    end
  end
end
