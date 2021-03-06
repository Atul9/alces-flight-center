
FactoryBot.define do

  factory :case_state_transition do
    association :case
    association :user, factory: :admin
    event 'resolve'
    from 'open'
    to 'resolved'
  end

  factory :case_comment do
    association :user, factory: :admin
    association :case # Avoid conflict with case keyword.
    text 'This is a comment'

    factory :case_comment_with_markdown_text do
      text "# Text title\n\nText body\n\n - Text list item 1\n"
    end
  end

  sequence :email do |n|
    "a.scientist.#{n}@liverpool.ac.uk"
  end

  factory :site do
    name 'Liverpool University'
  end

  factory :additional_contact do
    site
    email
  end

  factory :component_type do
    name 'server'
    ordering 5
  end

  factory :component_make do
    component_type
    manufacturer 'manufacturer'
    model 'model'
    knowledgebase_url 'knowledgebase_url'
  end

  factory :component_group do
    cluster
    component_make
    name 'nodes'
  end

  factory :expansion_type do
    name 'switch'
  end

  factory :default_expansion do
    expansion_type
    component_make
    ports 4
    slot 'a'
  end

  factory :category do
    name 'User management'
  end

  factory :asset_record_field_definition, aliases: [:definition] do
    field_name 'Manufacturer/model name'
    level :group
    data_type 'short_text'
  end

  factory :service_type do
    name 'Some Service'

    factory :automatic_service_type do
      automatic true
    end
  end

  factory :log do
    details 'I am the factory default details'
    cluster
    association :engineer, factory: :admin

    factory :log_with_markdown_details do
      details "# Details title\n\nDetails body\n\n - Details list item 1\n"
    end
  end

  factory :change_motd_request do
    motd 'Some new MOTD'
    association :case # Avoid conflict with case keyword.
  end

  factory :change_motd_request_state_transition do
    change_motd_request
    to :applied
  end

  factory :credit_charge do
    amount 1
    association :user, factory: :admin
    association :case
  end

  factory :change_request do
    association :case
    description 'Change request details text'
    credit_charge 1
  end

  factory :change_request_state_transition do
    association :change_request
    association :user, factory: :admin
    event 'propose'
    from 'draft'
    to 'awaiting_authorisation'
  end

  factory :collated_case_association_audit do
    skip_create  # since this isn't an ActiveRecord model
    association :user
    created_at DateTime.now

    initialize_with {
      component = create(:component)
      new(
        user.id,
        created_at,
        [
          create(
            :audit,
            action: 'create',
            audited_changes: {
              'associated_element_type': 'Component',
              'associated_element_id': component.id,
            }
          )
        ]
      )
    }

  end

  factory :audit, class: Audited::Audit do
    association :user
    action :update
    audited_changes []
  end
end
