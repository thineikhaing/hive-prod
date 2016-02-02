require 'rails_helper'

RSpec.describe "sg_accident_histories/index", type: :view do
  before(:each) do
    assign(:sg_accident_histories, [
      SgAccidentHistory.create!(
        :type => "Type",
        :message => "Message",
        :latitude => 1.5,
        :longitude => 1.5,
        :summary => "MyText",
        :notify => false
      ),
      SgAccidentHistory.create!(
        :type => "Type",
        :message => "Message",
        :latitude => 1.5,
        :longitude => 1.5,
        :summary => "MyText",
        :notify => false
      )
    ])
  end

  it "renders a list of sg_accident_histories" do
    render
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => "Message".to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
