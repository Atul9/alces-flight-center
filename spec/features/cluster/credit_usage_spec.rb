require 'rails_helper'

RSpec.describe 'Cluster credit usage', type: :feature do
  let(:site) { create(:site) }
  let(:admin) { create(:admin) }
  let(:user) { create(:contact, site: site) }
  let(:cluster) { create(:cluster, support_type: 'managed', site: site) }

  it 'shows credit events for the current period' do
    c1 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 1))
    c2 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 0))
    c3 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 4))

    cluster.credit_deposits.create!(amount: 10, user: admin, effective_date: Date.today)

    visit cluster_credit_usage_path(cluster, as: user)

    events = find_all('li.credit-charge-entry')

    expect(events.length).to eq 4

    expect(events[3].text).to match(/#{c3.display_id}.*4 credits$/)
    expect(events[2].text).to match(/#{c2.display_id}.*0 credits$/)
    expect(events[1].text).to match(/#{c1.display_id}.*1 credit$/)
    expect(events[0].text).to match(/Credits added.* 10 credits$/)

    expect(find('p.credit-balance').text).to eq '5 credits'
  end

  it 'shows a friendly message with no credit events' do
    visit cluster_credit_usage_path(cluster, as: user)

    expect(find('.no-events-message').text).to eq 'No credit usage or accrual in this period.'
  end

  describe 'navigation through time' do
    include ActiveSupport::Testing::TimeHelpers

    before(:each) do
      travel_to Time.zone.local(2017, 9, 30) do
        # Create cluster (implicitly) and charge event in Q3 2017
        create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 1))
      end

      travel_to Time.zone.local(2017, 10, 1) do
        # Create a deposit and charge in Q4 2017
        create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 2))
        cluster.credit_deposits.create(amount: 4, user: admin, effective_date: Time.zone.local(2017, 10, 1))
      end
    end

    it 'lists all quarters from cluster creation to present' do
      travel_to Time.zone.local(2018, 6, 1) do
        visit cluster_credit_usage_path(cluster, as: user)

        expect(find('p.credit-balance').text).to eq '1 credit'
        expect(find('.no-events-message').text).to eq 'No credit usage or accrual in this period.'

        form = find('#credit-quarter-selection')

        available_quarters = form.find_all('option').map(&:value)
        expect(available_quarters).to eq(%w(2018-04-01 2018-01-01 2017-10-01 2017-07-01))
      end
    end

    it 'lists events in selected quarters' do
      visit cluster_credit_usage_path(cluster, start_date: '2017-07-01', as: user)

      events = find_all('li.credit-charge-entry')

      expect(events.length).to eq 1
      expect(events[0].text).to match(/1 credit$/)

      visit cluster_credit_usage_path(cluster, start_date: '2017-10-01', as: user)

      events = find_all('li.credit-charge-entry')

      expect(events.length).to eq 2
      expect(events[1].text).to match(/2 credits$/)
      expect(events[0].text).to match(/Credits added.* 4 credits$/)

      visit cluster_credit_usage_path(cluster, start_date: '2018-01-01', as: user)

      events = find_all('li.credit-charge-entry')

      expect(events.length).to eq 0
    end
  end

  context 'when case is resolved in different quarter to when it was charged' do
    include ActiveSupport::Testing::TimeHelpers

    let(:kase) { create(:open_case, cluster: cluster, subject: 'Important case', time_worked: 1) }

    it 'uses resolution date to filter charge events' do
      travel_to Time.zone.local(2018, 6, 1) do  # Resolve in Q3 2018
        kase.resolve!(admin)
      end

      kase.reload
      expect(kase.resolution_date).to eq(Time.zone.local(2018, 6, 1))

      travel_to Time.zone.local(2018, 9, 1) do  # Close in Q4 2018
        kase.create_credit_charge(amount:1, user: admin)
        kase.close!
      end

      visit cluster_credit_usage_path(cluster, start_date: '2018-06-01', as: admin)
      events = find_all('li.credit-charge-entry')
      expect(events.length).to eq 1
      expect(events[0]).to have_text('Important case')

      visit cluster_credit_usage_path(cluster, start_date: '2018-09-01', as: admin)
      events = find_all('li.credit-charge-entry')
      expect(events.length).to eq 0
    end

  end

  describe 'credit deposits' do
    context 'as an admin' do
      it 'shows credit deposit form' do
        visit cluster_credit_usage_path(cluster, as: admin)

        expect do
          find('#credit-deposit-form')
        end.not_to raise_error
      end

      RSpec.shared_examples 'allows deposit' do
        it 'allows deposit' do
          visit cluster_credit_usage_path(cluster, as: admin)
          fill_in 'credit_deposit[amount]', with: 42
          fill_in 'credit_deposit[effective_date]', with: effective_date
          click_on 'Add credits'

          cluster.reload

          expect(cluster.credit_balance).to eq 42
          deposits = cluster.credit_deposits
          expect(cluster.credit_deposits.count).to eq 1
          expect(deposits[0].amount).to eq 42
          expect(deposits[0].effective_date).to eq effective_date

          expect(find('.alert-success')).to have_text('42 credits added to cluster')
        end
      end

      context 'for dates in the past' do
        let(:effective_date) { Date.today - 1.day }
        include_examples 'allows deposit'
      end

      context 'for today\'s date' do
        let(:effective_date) { Date.today }
        include_examples 'allows deposit'
      end

      context 'with dates in the future' do
        let(:effective_date) { Date.today + 1.day }
        it 'rejects deposit' do
          visit cluster_credit_usage_path(cluster, as: admin)
          fill_in 'credit_deposit[amount]', with: 42
          fill_in 'credit_deposit[effective_date]', with: effective_date
          click_on 'Add credits'

          cluster.reload
          expect(cluster.credit_balance).to eq 0
          expect(find('.alert-danger')).to have_text 'Effective date cannot be in the future'
        end
      end
    end

    context 'as a non-admin' do
      it 'does not show credit deposit form' do
        visit cluster_credit_usage_path(cluster, as: user)

        expect do
          find('#credit-deposit-form')
        end.to raise_error(Capybara::ElementNotFound)
      end
    end
  end
end
