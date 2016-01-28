require 'rails_helper'

RSpec.describe "lookups/show", type: :view do
  before(:each) do
    @lookup = assign(:lookup, Lookup.create!(
      :lookup_type => "Lookup Type",
      :name => "Name",
      :value => "Value"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Lookup Type/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Value/)
  end
end
