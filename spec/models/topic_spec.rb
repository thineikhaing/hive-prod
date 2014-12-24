require 'spec_helper'

describe Topic do

  it { should have_many(:posts) }
  #it { should belong_to(:hiveapplication)}
  it { should belong_to(:user)}
  it { should belong_to(:place)}

  let (:user) {FactoryGirl.create(:devuser, email: "user1@example.com", username: "testuser",password:"password")}
  let(:hiveapplication) {FactoryGirl.create(:hiveapplication, app_name: "test_app", app_type: "food",devuser_id:"#{user.id}",description: 'test description' )}
  let(:topic) {FactoryGirl.create(:topic, title: "topic1", data: "{'weather' => 'Sunny'}",user_id:"#{user.id}",hiveapplication_id: "#{hiveapplication.id}" )}

  context "tag_information methods" do
    it "returns the tag information for the topic"  do
        response = topic.tag_information
        expect(response).should_not be blank
    end
  end

end
