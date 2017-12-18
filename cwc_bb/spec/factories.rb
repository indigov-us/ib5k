FactoryGirl.define do

  factory :user, :class => CWC::User do
    sequence :email do |n|
      "user#{n}@cwc.house.com"
    end
    sequence(:first_name){"First#{n}"}
    sequence(:last_name){"Last#{n}"}
    sequence(:organization){"Org#{n}"}
    sequence(:phone){"Phone#{n}"}
    sequence(:activated){ true }
  end


end
