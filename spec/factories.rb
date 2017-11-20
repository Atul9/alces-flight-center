
FactoryBot.define do
  sequence :email do |n|
    "a.scientist.#{n}@liverpool.ac.uk"
  end

  factory :site do
    name 'Liverpool University'
  end

  factory :user do
    site
    name 'A Scientist'
    email
    password 'definitely_encrypted'

    factory :contact do
      admin false
    end

    factory :admin do
      admin true
      site nil
    end
  end

  factory :additional_contact do
    site
    email
  end

  factory :component_type do
    name 'server'
  end

  factory :component_group do
    cluster
    component_type
    name 'nodes'
  end

  factory :case_category do
    name 'User management'
  end

  factory :asset_record_field_definition do
    field_name 'Manufacturer/model name'
    level :group
  end

  factory :unassociated_asset_record_field, class: AssetRecordField do
    asset_record_field_definition
    value ''
  end

  factory :service_type do
    name 'Some Service'

    factory :automatic_service_type do
      automatic true
    end
  end

  factory :credit_deposit do
    cluster
    user { create(:admin) }
    amount 10
  end

  factory :credit_charge do
    add_attribute(:case) { create(:case) } # Avoid conflict with case keyword.
    user { create(:admin) }
    amount 2
  end

  factory :maintenance_window do
    add_attribute(:case) { create(:case) } # Avoid conflict with case keyword.
    user { create(:admin) }
    created_at 7.days.ago

    factory :open_maintenance_window {}

    factory :closed_maintenance_window do
      ended_at 3.days.ago
    end
  end
end
