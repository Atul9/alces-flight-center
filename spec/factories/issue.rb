
FactoryBot.define do
  factory :issue do
    name 'New user/group'
    requires_component false
    support_type :managed

    factory :advice_issue do
      support_type :advice
    end

    factory :issue_requiring_component do
      requires_component true
    end

    factory :issue_requiring_service do
      requires_service true
    end

    factory :request_component_becomes_advice_issue do
      identifier Issue::IDENTIFIERS.request_component_becomes_advice
    end

    factory :request_component_becomes_managed_issue do
      identifier Issue::IDENTIFIERS.request_component_becomes_managed
    end

    factory :request_service_becomes_advice_issue do
      identifier Issue::IDENTIFIERS.request_service_becomes_advice
    end

    factory :request_service_becomes_managed_issue do
      identifier Issue::IDENTIFIERS.request_service_becomes_managed
    end

    factory :special_issue do
      identifier Issue::IDENTIFIER_NAMES.first
    end
  end
end
