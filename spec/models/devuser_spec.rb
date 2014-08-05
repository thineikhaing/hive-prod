require 'spec_helper'

describe Devuser do
    pending "add some examples to (or delete) #{__FILE__}"
end



require 'spec_helper'

describe Devuser do
  #context "associations" do
  #  it { should have_many(:topics) }
  #  it { should have_many(:posts)  }
  #end

  context "after_initialize" do
    #let(:user) { FactoryGirl.build(:user) } # Factory excludes authentication_token and username

    let(:devuser) { @user_attr = FactoryGirl.attributes_for(:devuser);devuser.create!(@user_attr)}
  #  describe "#ensure_authentication_token" do
  #    it "sets authentication_token"do
  #      user.authentication_token.should_not be_blank
  #    end
  #  end
  #
  #  describe "#ensure_username" do
  #    it "sets username" do
  #      user.username.should_not be_blank
  #    end
  #  end
  #end
  #
  #describe "#initialize" do
  #  context "without email" do
  #    it "is valid with device_id" do
  #      user = User.new(device_id: "12345", password: Devise.friendly_token)
  #      user.should be_valid
  #    end
  #
  #    #it "is invalid without device_id" do
  #    #  user = User.new(password: Devise.friendly_token)
  #    #  user.should_not be_valid
  #    #end
  #  end
  end
end
