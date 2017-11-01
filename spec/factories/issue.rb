
FactoryGirl.define do
  factory :issue do
    case_category
    name 'New user/group'
    requires_component false
    details_template 'Enter the usernames to create'
    support_type :managed

    factory :advice_issue do
      support_type :advice
    end

    factory :issue_requiring_component do
      requires_component true
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
  end
end
