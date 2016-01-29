require 'rails_helper'

RSpec.describe "PrivacyPolicies", type: :request do
  describe "GET /privacy_policies" do
    it "works! (now write some real specs)" do
      get privacy_policies_path
      expect(response).to have_http_status(200)
    end
  end
end
