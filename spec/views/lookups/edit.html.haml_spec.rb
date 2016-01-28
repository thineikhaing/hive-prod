require 'rails_helper'

RSpec.describe "lookups/edit", type: :view do
  before(:each) do
    @lookup = assign(:lookup, Lookup.create!(
      :lookup_type => "MyString",
      :name => "MyString",
      :value => "MyString"
    ))
  end

  it "renders the edit lookup form" do
    render

    assert_select "form[action=?][method=?]", lookup_path(@lookup), "post" do

      assert_select "input#lookup_lookup_type[name=?]", "lookup[lookup_type]"

      assert_select "input#lookup_name[name=?]", "lookup[name]"

      assert_select "input#lookup_value[name=?]", "lookup[value]"
    end
  end
end
