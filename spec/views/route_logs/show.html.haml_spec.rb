require 'rails_helper'

RSpec.describe "route_logs/show", type: :view do
  before(:each) do
    @route_log = assign(:route_log, RouteLog.create!(
      :user_id => 1,
      :start_address => "Start Address",
      :end_address => "End Address",
      :start_latitude => 1.5,
      :start_longitude => 1.5,
      :end_latitude => 1.5,
      :end_longitude => 1.5,
      :transport_type => "Transport Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/1/)
    expect(rendered).to match(/Start Address/)
    expect(rendered).to match(/End Address/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/1.5/)
    expect(rendered).to match(/Transport Type/)
  end
end
