require 'rails_helper'

RSpec.describe "Lookups", type: :request do
  describe "GET /lookups" do
    it "works! (now write some real specs)" do
      get lookups_path
      expect(response).to have_http_status(200)
    end
  end
end
