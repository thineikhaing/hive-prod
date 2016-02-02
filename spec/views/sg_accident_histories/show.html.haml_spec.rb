require 'rails_helper'

RSpec.describe "sg_accident_histories/show", type: :view do
  before(:each) do
    @sg_accident_history = assign(:sg_accident_history, SgAccidentHistory.create!(
      :type => "Type",
      :message => "Message",
      :latitude => 1.5,
      :longitude => 1.5,
      :summary => "MyText",
      :notify => false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Type/)
    expect(rendered).to match(/Message/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/false/)
  end
end
