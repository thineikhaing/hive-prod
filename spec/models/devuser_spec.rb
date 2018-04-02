require 'spec_helper'

describe Devuser do
    it { should have_many(:hive_applications) }


  context "after_initialize" do
    let (:user) {FactoryBot.create(:devuser, email: "user1@example.com", username: "testuser",password:"password")}
    it "Test the user creation"do
        user.username.should_not be_blank
        user.reset_password_token.should be_blank
    end

    it "fails validation with no username (using errors_on)" do
      FactoryBot.build(:devuser, email: "user1@example.com", username: nil, password: "password").should_not be_valid
    end

    it "fails validation with no email (using errors_on)" do
      FactoryBot.build(:devuser, email: nil, username: "testuser", password: "password").should_not be_valid
    end

    it "fails validation with no password (using errors_on)" do
      FactoryBot.build(:devuser, email: "user1@example.com", username: "testuser", password: nil).should_not be_valid
    end

    describe "Sent reset password token to user" do
      it "should return user password token " do
        expect { user.send_password_reset }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.first.subject).to eql('Password Reset')
      end
    end

  end
end
