require 'rails_helper'

RSpec.describe "user_fav_locations/new", type: :view do
  before(:each) do
    assign(:user_fav_location, UserFavLocation.new(
      :user_id => 1,
      :place_id => 1,
      :place_type => "MyString"
    ))
  end

  it "renders new user_fav_location form" do
    render

    assert_select "form[action=?][method=?]", user_fav_locations_path, "post" do

      assert_select "input#user_fav_location_user_id[name=?]", "user_fav_location[user_id]"

      assert_select "input#user_fav_location_place_id[name=?]", "user_fav_location[place_id]"

      assert_select "input#user_fav_location_place_type[name=?]", "user_fav_location[place_type]"
    end
  end
end
