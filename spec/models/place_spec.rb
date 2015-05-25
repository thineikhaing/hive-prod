require 'spec_helper'

describe Place do

  it { should have_many(:topics) }



  context "after_initialize" do

    api_key = SecureRandom.hex

    let (:user) {FactoryGirl.create(:devuser, email: "user1@example.com", username: "testuser",password:"password")}
    let (:hiveapplication) {FactoryGirl.create(:hiveapplication, app_name: "test_app",
                                               app_type: "food",devuser_id:"#{user.id}",
                                               description: 'test description' ,
                                               api_key: api_key)}

    describe "get nearest topics within lat and long" do
      it "should get nearest topics within lat and long" do
        p response = Place.nearest_topics_within("44.968046", "-94.420307", 1, hiveapplication.id)
        expect{Place.nearest_topics_within("44.968046", "-94.420307", 1, hiveapplication.id)}

      end
    end


    describe "get nearest"       do
      it "should get nearest" do
        p response = Place.nearest("44.968046", "-94.420307", 1)
        expect{Place.nearest("44.968046", "-94.420307", 1)}

      end
    end
  end
end