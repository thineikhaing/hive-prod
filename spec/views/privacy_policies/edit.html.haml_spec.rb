require 'rails_helper'

RSpec.describe "privacy_policies/edit", type: :view do
  before(:each) do
    @privacy_policy = assign(:privacy_policy, PrivacyPolicy.create!(
      :title => "MyString",
      :content => "MyText"
    ))
  end

  it "renders the edit privacy_policy form" do
    render

    assert_select "form[action=?][method=?]", privacy_policy_path(@privacy_policy), "post" do

      assert_select "input#privacy_policy_title[name=?]", "privacy_policy[title]"

      assert_select "textarea#privacy_policy_content[name=?]", "privacy_policy[content]"
    end
  end
end
