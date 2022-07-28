FactoryBot.define do
  factory :manual_update_log do
    client_ip { Faker::Internet.ip_v4_address }
  end
end
