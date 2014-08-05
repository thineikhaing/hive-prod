# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :devuser do
    sequence :email do |n|
      "user#{n}@example.com"
    end
    password "password"
    sequence :username do |n|
      "user_name_#{n}"
    end
  end
end
