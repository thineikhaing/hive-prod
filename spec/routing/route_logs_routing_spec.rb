require "rails_helper"

RSpec.describe RouteLogsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/route_logs").to route_to("route_logs#index")
    end

    it "routes to #new" do
      expect(:get => "/route_logs/new").to route_to("route_logs#new")
    end

    it "routes to #show" do
      expect(:get => "/route_logs/1").to route_to("route_logs#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/route_logs/1/edit").to route_to("route_logs#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/route_logs").to route_to("route_logs#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/route_logs/1").to route_to("route_logs#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/route_logs/1").to route_to("route_logs#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/route_logs/1").to route_to("route_logs#destroy", :id => "1")
    end

  end
end
