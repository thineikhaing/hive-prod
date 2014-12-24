require 'spec_helper'

describe HiveApplication do

  it { should belong_to(:devuser)}
  it { should have_many(:topics)}


  context "after_initialize" do

    let (:user) {FactoryGirl.create(:devuser, email: "user1@example.com", username: "testuser",password:"password")}
    let (:hiveapplication) {FactoryGirl.create(:hiveapplication, app_name: "test_app", app_type: "food",devuser_id:"#{user.id}",description: 'test description' )}

    describe "should generate verification code" do
      it "should generate verification code " do

        expect {HiveApplication.generate_verification_code(16)}
        response = HiveApplication.generate_verification_code(16)
        p "Verification code ::::"
        p response
      end
    end

    describe "should add dev_user activation job"   do
      it "should add dev_user activation job" do
        expect {HiveApplication.add_dev_user_activation_job(user.id)}

        response = HiveApplication.add_dev_user_activation_job(user.id)
        p response
      end
    end

    describe "is it a vaild email?" do
      it "is it a vaild email?" do
        expect(HiveApplication.is_a_valid_email(user.email)).to eql(true)
      end
    end


    end
end
