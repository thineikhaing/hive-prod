require 'rails_helper'

RSpec.describe "SgAccidentHistories", type: :request do
  describe "GET /sg_accident_histories" do
    it "works! (now write some real specs)" do
      get sg_accident_histories_path
      expect(response).to have_http_status(200)
    end
  end
end
