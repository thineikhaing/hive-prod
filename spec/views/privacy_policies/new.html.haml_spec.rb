require 'rails_helper'

RSpec.describe "privacy_policies/new", type: :view do
  before(:each) do
    assign(:privacy_policy, PrivacyPolicy.new(
      :title => "MyString",
      :content => "MyText"
    ))
  end

  it "renders new privacy_policy form" do
    render

    assert_select "form[action=?][method=?]", privacy_policies_path, "post" do

      assert_select "input#privacy_policy_title[name=?]", "privacy_policy[title]"

      assert_select "textarea#privacy_policy_content[name=?]", "privacy_policy[content]"
    end
  end
end
