require 'rails_helper'

RSpec.describe "route_logs/new", type: :view do
  before(:each) do
    assign(:route_log, RouteLog.new(
      :user_id => 1,
      :start_address => "MyString",
      :end_address => "MyString",
      :start_latitude => 1.5,
      :start_longitude => 1.5,
      :end_latitude => 1.5,
      :end_longitude => 1.5,
      :transport_type => "MyString"
    ))
  end

  it "renders new route_log form" do
    render

    assert_select "form[action=?][method=?]", route_logs_path, "post" do

      assert_select "input#route_log_user_id[name=?]", "route_log[user_id]"

      assert_select "input#route_log_start_address[name=?]", "route_log[start_address]"

      assert_select "input#route_log_end_address[name=?]", "route_log[end_address]"

      assert_select "input#route_log_start_latitude[name=?]", "route_log[start_latitude]"

      assert_select "input#route_log_start_longitude[name=?]", "route_log[start_longitude]"

      assert_select "input#route_log_end_latitude[name=?]", "route_log[end_latitude]"

      assert_select "input#route_log_end_longitude[name=?]", "route_log[end_longitude]"

      assert_select "input#route_log_transport_type[name=?]", "route_log[transport_type]"
    end
  end
end
