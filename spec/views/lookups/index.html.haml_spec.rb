require 'rails_helper'

RSpec.describe "lookups/index", type: :view do
  before(:each) do
    assign(:lookups, [
      Lookup.create!(
        :lookup_type => "Lookup Type",
        :name => "Name",
        :value => "Value"
      ),
      Lookup.create!(
        :lookup_type => "Lookup Type",
        :name => "Name",
        :value => "Value"
      )
    ])
  end

  it "renders a list of lookups" do
    render
    assert_select "tr>td", :text => "Lookup Type".to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Value".to_s, :count => 2
  end
end
