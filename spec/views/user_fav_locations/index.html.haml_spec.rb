require 'rails_helper'

RSpec.describe "user_fav_locations/index", type: :view do
  before(:each) do
    assign(:user_fav_locations, [
      UserFavLocation.create!(
        :user_id => 1,
        :place_id => 2,
        :place_type => "Place Type"
      ),
      UserFavLocation.create!(
        :user_id => 1,
        :place_id => 2,
        :place_type => "Place Type"
      )
    ])
  end

  it "renders a list of user_fav_locations" do
    render
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Place Type".to_s, :count => 2
  end
end
