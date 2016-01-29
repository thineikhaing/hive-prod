require "rails_helper"

RSpec.describe PrivacyPoliciesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/privacy_policies").to route_to("privacy_policies#index")
    end

    it "routes to #new" do
      expect(:get => "/privacy_policies/new").to route_to("privacy_policies#new")
    end

    it "routes to #show" do
      expect(:get => "/privacy_policies/1").to route_to("privacy_policies#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/privacy_policies/1/edit").to route_to("privacy_policies#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/privacy_policies").to route_to("privacy_policies#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/privacy_policies/1").to route_to("privacy_policies#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/privacy_policies/1").to route_to("privacy_policies#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/privacy_policies/1").to route_to("privacy_policies#destroy", :id => "1")
    end

  end
end
