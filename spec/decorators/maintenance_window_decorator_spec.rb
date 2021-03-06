require 'rails_helper'

RSpec.describe MaintenanceWindowDecorator do
  describe '#transition_info' do
    subject do
      create(:maintenance_window)
        .tap { |w| w.request!(requestor) }
        .decorate
    end

    let(:requestor) { create(:admin, name: 'Some User') }

    it 'gives string with info on transition to this state' do
      info = subject.transition_info(:requested)

      user_name = requestor.name
      date_time = subject.requested_at.to_formatted_s(:short)
      expect(info).to eq(
        h.raw("By <em>#{user_name}</em> on <em>#{date_time}</em>")
      )
    end

    it 'gives false for transition which has not occurred' do
      info = subject.transition_info(:confirmed)

      expect(info).to be false
    end
  end

  describe '#scheduled_period' do
    subject do
      create(
        :maintenance_window,
        requested_start: 1.days.from_now,
        duration: 3,
        state: state,
      ).decorate
    end

    let :expected_time_range do
      start_date = subject.requested_start.to_formatted_s(:short)
      end_date = subject.expected_end.to_formatted_s(:short)
      h.raw("#{start_date} &mdash; #{end_date}")
    end

    RSpec.shared_examples 'includes time range' do
      it 'returns formatted time range for maintenance' do
        expect(subject.scheduled_period).to include expected_time_range
      end
    end

    context 'when started' do
      let(:state) { :started }

      include_examples 'includes time range'

      it 'indicates that the maintenance is in progress' do
        expect(subject.scheduled_period).to include '<strong>(in progress)</strong>'
      end
    end

    context 'when expired' do
      let(:state) { :expired }

      include_examples 'includes time range'

      it 'indicates that the maintenance was not confirmed and has now expired' do
        expect(subject.scheduled_period).to match(
          /<strong title=".* maintenance .* not confirmed .*">\(expired\)<\/strong>/
        )
      end
    end

    other_states = MaintenanceWindow.possible_states - [:started, :expired]
    other_states.each do |state|
      context "when #{state}" do
        let(:state) { state }

        it 'includes state' do
          expect(subject.scheduled_period).to include "(#{state})"
        end
      end
    end
  end
end
