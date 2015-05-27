require 'rails_helper'

RSpec.describe "car_action_logs/edit", :type => :view do
  before(:each) do
    @car_action_log = assign(:car_action_log, CarActionLog.create!(
      :user_id => 1,
      :speed => "",
      :direction => 1,
      :latitude => 1.5,
      :longitude => 1.5,
      :activity => "MyString",
      :heartrate => "MyString"
    ))
  end

  it "renders the edit car_action_log form" do
    render

    assert_select "form[action=?][method=?]", car_action_log_path(@car_action_log), "post" do

      assert_select "input#car_action_log_user_id[name=?]", "car_action_log[user_id]"

      assert_select "input#car_action_log_speed[name=?]", "car_action_log[speed]"

      assert_select "input#car_action_log_direction[name=?]", "car_action_log[direction]"

      assert_select "input#car_action_log_latitude[name=?]", "car_action_log[latitude]"

      assert_select "input#car_action_log_longitude[name=?]", "car_action_log[longitude]"

      assert_select "input#car_action_log_activity[name=?]", "car_action_log[activity]"

      assert_select "input#car_action_log_heartrate[name=?]", "car_action_log[heartrate]"
    end
  end
end
