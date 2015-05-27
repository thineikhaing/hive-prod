require 'rails_helper'

RSpec.describe "car_action_logs/show", :type => :view do
  before(:each) do
    @car_action_log = assign(:car_action_log, CarActionLog.create!(
      :user_id => 1,
      :speed => "",
      :direction => 2,
      :latitude => 1.5,
      :longitude => 1.5,
      :activity => "Activity",
      :heartrate => "Heartrate"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/1/)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/Activity/)
    expect(rendered).to match(/Heartrate/)
  end
end
