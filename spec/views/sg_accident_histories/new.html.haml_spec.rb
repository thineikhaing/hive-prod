require 'rails_helper'

RSpec.describe "sg_accident_histories/new", type: :view do
  before(:each) do
    assign(:sg_accident_history, SgAccidentHistory.new(
      :type => "",
      :message => "MyString",
      :latitude => 1.5,
      :longitude => 1.5,
      :summary => "MyText",
      :notify => false
    ))
  end

  it "renders new sg_accident_history form" do
    render

    assert_select "form[action=?][method=?]", sg_accident_histories_path, "post" do

      assert_select "input#sg_accident_history_type[name=?]", "sg_accident_history[type]"

      assert_select "input#sg_accident_history_message[name=?]", "sg_accident_history[message]"

      assert_select "input#sg_accident_history_latitude[name=?]", "sg_accident_history[latitude]"

      assert_select "input#sg_accident_history_longitude[name=?]", "sg_accident_history[longitude]"

      assert_select "textarea#sg_accident_history_summary[name=?]", "sg_accident_history[summary]"

      assert_select "input#sg_accident_history_notify[name=?]", "sg_accident_history[notify]"
    end
  end
end
