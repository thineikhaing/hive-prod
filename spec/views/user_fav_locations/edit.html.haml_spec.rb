require 'rails_helper'

RSpec.describe "user_fav_locations/edit", type: :view do
  before(:each) do
    @user_fav_location = assign(:user_fav_location, UserFavLocation.create!(
      :user_id => 1,
      :place_id => 1,
      :place_type => "MyString"
    ))
  end

  it "renders the edit user_fav_location form" do
    render

    assert_select "form[action=?][method=?]", user_fav_location_path(@user_fav_location), "post" do

      assert_select "input#user_fav_location_user_id[name=?]", "user_fav_location[user_id]"

      assert_select "input#user_fav_location_place_id[name=?]", "user_fav_location[place_id]"

      assert_select "input#user_fav_location_place_type[name=?]", "user_fav_location[place_type]"
    end
  end
end
