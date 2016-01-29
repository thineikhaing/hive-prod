require 'rails_helper'

RSpec.describe "privacy_policies/show", type: :view do
  before(:each) do
    @privacy_policy = assign(:privacy_policy, PrivacyPolicy.create!(
      :title => "Title",
      :content => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
  end
end
