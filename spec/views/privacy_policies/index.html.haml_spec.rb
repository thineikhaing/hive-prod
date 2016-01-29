require 'rails_helper'

RSpec.describe "privacy_policies/index", type: :view do
  before(:each) do
    assign(:privacy_policies, [
      PrivacyPolicy.create!(
        :title => "Title",
        :content => "MyText"
      ),
      PrivacyPolicy.create!(
        :title => "Title",
        :content => "MyText"
      )
    ])
  end

  it "renders a list of privacy_policies" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
