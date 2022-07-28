FactoryBot.define do
  factory :result do
    type 'Result'
    association :gateway
    upload { Random.rand(0..6.5).round(5) }
    download { Random.rand(0..6.5).round(5) }
  end

  factory :manual_result, parent: :result, class: 'ManualResult' do
    type 'ManualResult'
  end
end
