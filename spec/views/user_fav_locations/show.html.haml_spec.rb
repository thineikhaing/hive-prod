require 'rails_helper'

RSpec.describe "user_fav_locations/show", type: :view do
  before(:each) do
    @user_fav_location = assign(:user_fav_location, UserFavLocation.create!(
      :user_id => 1,
      :place_id => 2,
      :place_type => "Place Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/1/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Place Type/)
  end
end
