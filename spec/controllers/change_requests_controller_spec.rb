require 'rails_helper'

RSpec.describe ChangeRequestsController, type: :controller do
  let :stub_mail do
    obj = double
    expect(obj).to receive(:deliver_later)
    obj
  end

  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }
  let(:admin) { create(:admin) }
  let(:contact) { create(:contact, site: site) }
  let(:kase) { build(:open_case, tier_level: 4, cluster: cluster)}

  EXPECTED_BEHAVIOURS = [ # initial_state, action, user, message, next_state
    [:draft, :propose, :admin, 'has been proposed and is awaiting your authorisation.', :awaiting_authorisation],
    [:awaiting_authorisation, :authorise, :contact, 'has been authorised.', :in_progress],
    [:awaiting_authorisation, :decline, :contact, 'has been declined.', :declined],
    [:in_progress, :handover, :admin, 'is ready for handover.', :in_handover],
    [:in_handover, :complete, :contact, 'is now complete.', :completed],
  ].freeze

  describe 'state transition methods' do

    EXPECTED_BEHAVIOURS.each do |initial_state, action, user, message, next_state|
      it "transitions from #{initial_state} to #{next_state}" do

        cr = create(:change_request, case: kase, state: initial_state)

        expect(CaseMailer).to receive(:change_request).with(
          kase,
          message,
          send(user)
        ).and_return(stub_mail)

        sign_in_as(send(user))
        post action, params: { case_id: kase.id }

        cr.reload

        expect(cr.state).to eq next_state.to_s
      end
    end

    it 'does not allow illegal state transitions' do
      cr = create(:change_request, case: kase, state: :draft)

      sign_in_as(contact)
      post :complete, params: { case_id: kase.id }

      cr.reload
      expect(cr.state).to eq 'draft'
      expect(flash[:error]).to eq 'Error updating change request: state cannot transition via "complete"'
    end

  end
end
