require "rails_helper"

RSpec.describe CarActionLogsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/car_action_logs").to route_to("car_action_logs#index")
    end

    it "routes to #new" do
      expect(:get => "/car_action_logs/new").to route_to("car_action_logs#new")
    end

    it "routes to #show" do
      expect(:get => "/car_action_logs/1").to route_to("car_action_logs#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/car_action_logs/1/edit").to route_to("car_action_logs#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/car_action_logs").to route_to("car_action_logs#create")
    end

    it "routes to #update" do
      expect(:put => "/car_action_logs/1").to route_to("car_action_logs#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/car_action_logs/1").to route_to("car_action_logs#destroy", :id => "1")
    end

  end
end
