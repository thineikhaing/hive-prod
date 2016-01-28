require 'rails_helper'

RSpec.describe "lookups/new", type: :view do
  before(:each) do
    assign(:lookup, Lookup.new(
      :lookup_type => "MyString",
      :name => "MyString",
      :value => "MyString"
    ))
  end

  it "renders new lookup form" do
    render

    assert_select "form[action=?][method=?]", lookups_path, "post" do

      assert_select "input#lookup_lookup_type[name=?]", "lookup[lookup_type]"

      assert_select "input#lookup_name[name=?]", "lookup[name]"

      assert_select "input#lookup_value[name=?]", "lookup[value]"
    end
  end
end
