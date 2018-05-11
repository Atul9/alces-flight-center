require 'rails_helper'

RSpec.describe IssueDecorator do
  describe '#case_form_json' do
    subject do
      create(
        :issue,
        id: 1,
        name: 'New user request',
        requires_component: false,
        requires_service: service_type.present?,
        service_type: service_type,
        support_type: :managed,
        chargeable: true,
        tiers: [tier]
      ).tap do |issue|
        # Issue creates a Tier by default on create, so remove any associated
        # Tier other than the one we want for straightforward tests.
        issue.tiers.each { |t| t.destroy! unless t == tier }
        issue.tiers.reload
      end.decorate
    end

    let :service_type { create(:service_type) }
    let :tier { create(:tier) }

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'New user request',
        defaultSubject: 'New user request',
        requiresComponent: false,
        supportType: 'managed',
        chargeable: true,
        tiers: [tier.case_form_json]
      )
    end
  end
end
