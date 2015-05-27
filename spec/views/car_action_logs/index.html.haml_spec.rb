require 'rails_helper'

RSpec.describe "car_action_logs/index", :type => :view do
  before(:each) do
    assign(:car_action_logs, [
      CarActionLog.create!(
        :user_id => 1,
        :speed => "",
        :direction => 2,
        :latitude => 1.5,
        :longitude => 1.5,
        :activity => "Activity",
        :heartrate => "Heartrate"
      ),
      CarActionLog.create!(
        :user_id => 1,
        :speed => "",
        :direction => 2,
        :latitude => 1.5,
        :longitude => 1.5,
        :activity => "Activity",
        :heartrate => "Heartrate"
      )
    ])
  end

  it "renders a list of car_action_logs" do
    render
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => "Activity".to_s, :count => 2
    assert_select "tr>td", :text => "Heartrate".to_s, :count => 2
  end
end
