require 'rails_helper'

RSpec.describe "route_logs/index", type: :view do
  before(:each) do
    assign(:route_logs, [
      RouteLog.create!(
        :user_id => 1,
        :start_address => "Start Address",
        :end_address => "End Address",
        :start_latitude => 1.5,
        :start_longitude => 1.5,
        :end_latitude => 1.5,
        :end_longitude => 1.5,
        :transport_type => "Transport Type"
      ),
      RouteLog.create!(
        :user_id => 1,
        :start_address => "Start Address",
        :end_address => "End Address",
        :start_latitude => 1.5,
        :start_longitude => 1.5,
        :end_latitude => 1.5,
        :end_longitude => 1.5,
        :transport_type => "Transport Type"
      )
    ])
  end

  it "renders a list of route_logs" do
    render
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Start Address".to_s, :count => 2
    assert_select "tr>td", :text => "End Address".to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => "Transport Type".to_s, :count => 2
  end
end
