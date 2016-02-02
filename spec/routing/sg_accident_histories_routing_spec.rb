require "rails_helper"

RSpec.describe SgAccidentHistoriesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/sg_accident_histories").to route_to("sg_accident_histories#index")
    end

    it "routes to #new" do
      expect(:get => "/sg_accident_histories/new").to route_to("sg_accident_histories#new")
    end

    it "routes to #show" do
      expect(:get => "/sg_accident_histories/1").to route_to("sg_accident_histories#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/sg_accident_histories/1/edit").to route_to("sg_accident_histories#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/sg_accident_histories").to route_to("sg_accident_histories#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/sg_accident_histories/1").to route_to("sg_accident_histories#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/sg_accident_histories/1").to route_to("sg_accident_histories#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/sg_accident_histories/1").to route_to("sg_accident_histories#destroy", :id => "1")
    end

  end
end
