FactoryBot.define do
  factory :gateway do
    name  { Gateway::NAMES.shuffle.first }
    ip { Faker::Internet.ip_v4_address }
  end
end
