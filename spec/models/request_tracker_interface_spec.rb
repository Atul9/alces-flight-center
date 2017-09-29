require 'rails_helper'

RSpec.shared_examples 'Request Tracker interface' do
  subject { described_class.new }

  let :new_ticket_params do
    {
      requestor_email: 'test@example.com',
      subject: 'Supportware test ticket - please delete',
      text: <<-EOF.strip_heredoc
            Testing
            multiline
            text
            works
      EOF
    }
  end

  describe '#create_ticket' do
    it 'creates a ticket and returns object with id' do
      VCR.use_cassette('rt_create_ticket', re_record_interval: 7.days) do
        ticket = subject.create_ticket(new_ticket_params)

        # All tickets now have IDs greater than this.
        expect(ticket.id).to be > 10000
      end
    end
  end
end

RSpec.describe RequestTrackerInterface do
  it_behaves_like 'Request Tracker interface'
end

RSpec.describe FakeRequestTrackerInterface do
  include_context 'Request Tracker interface'

  describe '#create_ticket' do
    it 'produces tickets with incrementing IDs' do
      # Mock that we have a Case with the current maximum rt ticket id.
      max_rt_ticket_id = 10001
      allow(Case).to receive(:maximum).and_return(max_rt_ticket_id)

      new_rt_ticket_id = subject.create_ticket(new_ticket_params).id
      expect(new_rt_ticket_id).to eq(max_rt_ticket_id + 1)
    end
  end
end
