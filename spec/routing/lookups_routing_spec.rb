require "rails_helper"

RSpec.describe LookupsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/lookups").to route_to("lookups#index")
    end

    it "routes to #new" do
      expect(:get => "/lookups/new").to route_to("lookups#new")
    end

    it "routes to #show" do
      expect(:get => "/lookups/1").to route_to("lookups#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/lookups/1/edit").to route_to("lookups#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/lookups").to route_to("lookups#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/lookups/1").to route_to("lookups#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/lookups/1").to route_to("lookups#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/lookups/1").to route_to("lookups#destroy", :id => "1")
    end

  end
end
