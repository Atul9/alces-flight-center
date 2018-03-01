require 'rails_helper'

RSpec.describe ProgressMaintenanceWindow do
  describe '#progress' do
    RSpec.shared_examples 'progresses' do |args|
      from = args[:from]
      to = args[:to]

      it "progresses #{from} window to #{to}" do
        window = test_progression(
          initial_state: from,
          expected_state: to,
          expected_message: "#{from} -> #{to}"
        )

        # Need to check that the transition model is created when the window is
        # created to avoid gotcha with `state_machines` Gem where implicit
        # transitions do not fire callbacks (see
        # https://github.com/state-machines/state_machines-activerecord/issues/47).
        corresponding_transitions =
          window.transitions.where(from: from, to: to)
        expect(corresponding_transitions.length).to eq 1
      end
    end

    RSpec.shared_examples 'does not progress' do |states|
      it "does not progress window in states: #{states.join(', ').strip}" do
        states.each do |state|
          test_progression(
            initial_state: state,
            expected_state: state,
            expected_message: "remains #{state}"
          )
        end
      end
    end

    RSpec.shared_examples 'progresses unstarted windows' do
      include_examples 'progresses', from: :confirmed, to: :started
      include_examples 'progresses', from: :new, to: :expired
      include_examples 'progresses', from: :requested, to: :expired
    end

    def create_window(state:)
      create(
        :maintenance_window,
        state: state,
        requested_start: requested_start,
        requested_end: requested_end,
        component: component,
      )
    end

    def test_progression(initial_state:, expected_state:, expected_message:)
      window = create_window(state: initial_state)

      result = described_class.new(window).progress

      expect(window.state.to_sym).to eq expected_state
      test_progression_message(
        message: result,
        window: window,
        expected: expected_message
      )

      # Return window so any other needed assertions can be made on it.
      window
    end

    def test_progression_message(message:, window:, expected:)
      start_date = window.requested_start.to_formatted_s(:short)
      end_date = window.requested_end.to_formatted_s(:short)
      full_expected_message = <<~EOF.squish
        Maintenance window #{window.id} (#{component.name} | #{start_date} -
        #{end_date}): #{expected}
      EOF
      expect(message).to eq full_expected_message
    end

    let :component do
      create(:component, name: 'somenode')
    end

    context 'when requested_start and requested_end in future' do
      let :requested_start { DateTime.current.advance(days: 1) }
      let :requested_end { DateTime.current.advance(days: 2) }

      include_examples 'does not progress', MaintenanceWindow.possible_states
    end

    context 'when just requested_start passed' do
      let :requested_start { 1.hours.ago }
      let :requested_end { DateTime.current.advance(days: 1) }

      include_examples 'progresses unstarted windows'

      other_states = MaintenanceWindow.possible_states - [:confirmed, :new, :requested]
      include_examples 'does not progress', other_states
    end

    context 'when requested_start and requested_end passed' do
      let :requested_start { 2.hours.ago }
      let :requested_end { 1.hours.ago }

      # If both `requested_start` and `requested_end` have passed and a window
      # has still not transitioned from an unstarted state (e.g. if the
      # maintenance period is very short or we have not progressed
      # MaintenanceWindows for a while for some reason), then we still want to
      # ensure the window is appropriately transitioned out of the unstarted
      # state so that any actions which should occur when this happens do still
      # occur. The window will still be ended if needed soon enough, as soon as
      # we next progress MaintenanceWindows.
      include_examples 'progresses unstarted windows'

      include_examples 'progresses', from: :started, to: :ended

      other_states = MaintenanceWindow.possible_states - [:started, :confirmed, :new, :requested]
      include_examples 'does not progress', other_states
    end
  end
end