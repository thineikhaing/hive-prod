require 'rails_helper'

RSpec.describe "CarActionLogs", :type => :request do
  describe "GET /car_action_logs" do
    it "works! (now write some real specs)" do
      get car_action_logs_path
      expect(response).to have_http_status(200)
    end
  end
end
