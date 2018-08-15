require 'rails_helper'

RSpec.describe 'Case page', type: :feature do
  let! (:contact) { create(:contact, site: site) }
  let! (:admin) { create(:admin) }
  let (:site) { create(:site, name: 'My Site') }
  let (:cluster) { create(:cluster, site: site) }
  let (:assignee) { nil }
  let(:time_worked) { 42 }

  let :open_case do
    create(
      :open_case,
      cluster: cluster,
      subject: 'Open case',
      assignee: assignee,
      tier_level: 2,
      time_worked: time_worked
    )
  end

  let :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case', tier_level: 2)
  end

  let :closed_case do
    create(:closed_case, cluster: cluster, subject: 'Closed case', completed_at: 2.days.ago, tier_level: 2)
  end

  let :consultancy_case do
    create(:open_case, cluster: cluster, subject: 'Open case', assignee: assignee, tier_level: 3)
  end

  let(:mw) { create(:maintenance_window, case: open_case, clusters: [cluster]) }

  let(:comment_form_class) { '#new_case_comment' }
  let(:comment_button_text) { 'Add new comment' }

  describe 'data display' do
    it 'shows table of fields for Case with fields' do
      field_name = 'Some field'
      field_value = 'Some value'
      kase = create(
        :case,
        fields: [{name: field_name, value: field_value}],
        cluster: cluster
      )

      visit cluster_case_path(kase.cluster, kase, as: contact)

      header_text = all('th').map(&:text)
      expect(header_text).to include(field_name)
      data_text = all('td').map(&:text)
      expect(data_text).to include(field_value)
    end

    it 'shows requested MOTD for Case with associated ChangeMotdRequest' do
      motd = 'Some new MOTD'
      kase = create(
        :case,
        fields: nil,
        cluster: cluster,
        change_motd_request: build(:change_motd_request, motd: motd),
      )

      visit cluster_case_path(kase.cluster, kase, as: contact)

      data_text = all('td').map(&:text)
      expect(data_text).to include(motd)
    end
  end

  describe 'events list' do
    it 'shows events in reverse chronological order' do
      create(:case_comment, case: open_case, user: admin, created_at: 2.hours.ago, text: 'Second')
      create(
        :maintenance_window_state_transition,
      maintenance_window: mw,
      user: admin,
      event: :request
      )
      create(:case_comment, case: open_case, user: admin, created_at: 4.hours.ago, text: 'First')

      # Generate an assignee-change audit entry
      open_case.assignee = admin
      # ...and a time-worked one
      open_case.time_worked = 123
      # And an escalation entry
      open_case.tier_level = 3
      open_case.save

      # And a log entry
      create(:log, cases: [open_case], cluster: cluster, details: 'Loggy McLogface')

      # And a change request
      cr = create(:change_request, case: open_case, state: 'draft')
      create(:change_request_state_transition, event: 'propose', user: admin, change_request: cr)

      visit cluster_case_path(cluster, open_case, as: admin)

      event_cards = all('.event-card')
      expect(event_cards.size).to eq(8)

      expect(event_cards[7].find('.card-body').text).to eq('First')
      expect(event_cards[6].find('.card-body').text).to eq('Second')
      expect(event_cards[5].find('.card-body').text).to match(
        /Maintenance requested for .* from .* until .* by A Scientist; to proceed this maintenance must be confirmed on the cluster dashboard/
      )
      expect(event_cards[4].find('.card-body').text).to eq 'Changed time worked from 42m to 2h 3m.'

      expect(event_cards[3].find('.card-body').text).to eq(
          'Assigned this case to A Scientist.'
      )
      expect(event_cards[2].find('.card-body').text).to eq(
          'Escalated this case to tier 3 (General Support).'
      )
      expect(event_cards[1].find('.card-body').text).to eq(
          'Loggy McLogface'
      )
      expect(event_cards[0].find('.card-body').text).to eq(
        'Change request has been proposed and is awaiting your authorisation. View change request'
      )
    end

    it 'does not show time-worked events to contacts' do
      open_case.time_worked = 1138
      open_case.save

      visit cluster_case_path(cluster, open_case, as: contact)

      open_case.reload

      expect(open_case.audits.count).to eq 1  # It's there...
      expect do
        find('.event-card')
      end.to raise_error(Capybara::ElementNotFound) # ...but we don't show it
    end

    it 'renders comments and logs as markdown' do
      create(:case_comment,
             case: open_case,
             user: admin,
             created_at: 4.hours.ago,
             text: '**Commenty** *McCommentface*')
      create(:log,
             cases: [open_case],
             cluster: cluster,
             details: '*Loggy* **McLogface**')

      visit cluster_case_path(cluster, open_case, as: admin)

      event_cards = all('.event-card')
      expect(event_cards.size).to eq(2)

      log_html = event_cards[0].find('.card-body').native.inner_html
      case_comment_html = event_cards[1].find('.card-body').native.inner_html

      expect(log_html.strip).to eq("<div class=\"markdown\">\n<p><em>Loggy</em> <strong>McLogface</strong></p>\n</div>")
      expect(case_comment_html.strip).to eq("<div class=\"markdown\">\n<p><strong>Commenty</strong> <em>McCommentface</em></p>\n</div>")
    end

    it 'shows a card for creation of CreditCharge' do
      visit cluster_case_path(cluster, closed_case, as: admin)
      expect(find('.event-card').find('.card-body')).to have_text 'A charge of 1 credit was added for this case.'
    end
  end

  describe 'comments form' do
    it 'shows or hides add comment form for contacts' do
      visit cluster_case_path(cluster, consultancy_case, as: contact)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit cluster_case_path(cluster, open_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)

      # Observe that case state overrides case tier in terms of why we report commenting
      # being disabled.
      visit cluster_case_path(cluster, resolved_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is resolved.'

      visit cluster_case_path(cluster, closed_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is closed.'
    end

    it 'shows or hides add comment form for admins' do
      visit cluster_case_path(cluster, consultancy_case, as: admin)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit cluster_case_path(cluster, open_case, as: admin)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit cluster_case_path(cluster, resolved_case, as: admin)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is resolved.'

      visit cluster_case_path(cluster,closed_case, as: admin)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is closed.'
    end
  end

  describe 'state controls' do
    it 'hides state controls for contacts' do
      visit cluster_case_path(cluster,open_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

      visit cluster_case_path(cluster,resolved_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

      visit cluster_case_path(cluster,closed_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'shows or hides state controls for admins' do
      visit cluster_case_path(cluster, open_case, as: admin)

      expect(find('#case-state-controls').find('a').text).to eq 'Resolve this case'

      visit cluster_case_path(cluster,resolved_case, as: admin)
      expect(find('#case-state-controls').find('input[type=submit]').value).to eq 'Set charge and close case'

      visit cluster_case_path(cluster,closed_case, as: admin)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'requires a charge to be specified to close a case' do
      visit cluster_case_path(cluster,resolved_case, as: admin)
      fill_in 'credit_charge_amount', with: ''
      click_button 'Set charge and close case'

      resolved_case.reload
      expect(resolved_case.state).to eq 'resolved'
      expect(find('.alert')).to have_text 'Error updating support case: credit_charge is invalid'
    end

    let(:cr_case) {
      create(:resolved_case, tier_level: 4, change_request: cr, cluster: cluster)
    }

    context 'with a declined change request' do
      let(:cr) {
        build(
          :change_request,
          credit_charge: 42,
          state: 'declined'
        )
      }

      it 'does not use CR charge as a minimum' do
        visit cluster_case_path(cluster, cr_case, as: admin)

        expect(find('#credit_charge_amount').value).to eq "0"
      end
    end

    context 'with a completed change request' do
      let!(:cr) {
        build(
          :change_request,
          credit_charge: 42,
          state: 'completed'
        )
      }

      it 'uses CR charge as a minimum' do
        visit cluster_case_path(cluster,cr_case, as: admin)

        expect(find('#credit_charge_amount').value).to eq "42"
        expect(find('#case-state-controls')).to have_text 'Charge below should include 42 credits from attached CR'
      end
    end

    (MaintenanceWindow.possible_states - MaintenanceWindow.finished_states)
      .map(&:to_s).each do |state|
      context "with a #{state} maintenance window" do
        let!(:mw) {
          create(
            :maintenance_window,
            case: open_case,
            state: state,
            clusters: [open_case.cluster]
          )
        }

        before(:each) do
          visit cluster_case_path(open_case.cluster, open_case, as: admin)
        end

        it 'does not allow case to be resolved' do
          state_controls = find('#case-state-controls')
          expect(state_controls).to have_text 'outstanding maintenance window.'
          expect(state_controls).not_to have_text 'Resolve this case'
        end

        it 'shows maintenance details' do
          details = find('#maintenance-details')
          expect(details).to have_text("(#{state == 'started' ? 'in progress' : state})")
        end
      end
    end

    MaintenanceWindow.finished_states.map(&:to_s).each do |state|
      context "with a #{state} maintenance window" do
        let!(:mw) {
          create(
            :maintenance_window,
            case: open_case,
            state: state,
            clusters: [open_case.cluster]
          )
        }

        before(:each) do
          visit cluster_case_path(open_case.cluster, open_case, as: admin)
        end

        it 'allows case to be resolved' do
          visit cluster_case_path(open_case.cluster, open_case, as: admin)

          state_controls = find('#case-state-controls')
          expect(state_controls).not_to have_text 'outstanding maintenance window.'
          expect(state_controls.find('a')).to have_text 'Resolve this case'
        end

        it 'does not show maintenance details' do
          expect do
            find('#maintenance-details')
          end.to raise_error Capybara::ElementNotFound
        end
      end
    end

    context 'without time added' do
      let(:time_worked) { nil }

      it 'does not allow case to be resolved' do
        visit cluster_case_path(open_case.cluster, open_case, as: admin)
        state_controls = find('#case-state-controls')
        expect(state_controls).to have_text 'until time worked is added.'
        expect(state_controls).not_to have_text 'Resolve this case'
      end
    end
  end

  describe 'case assignment' do

    let(:emails) { ActionMailer::Base.deliveries }

    it 'hides assignment controls for contacts' do
      visit cluster_case_path(cluster, open_case, as: contact)
      assignment_td = find('#case-assignment')
      expect { assignment_td.find('input') }.to raise_error(Capybara::ElementNotFound)
      expect(assignment_td.text).to eq('Nobody')
    end

    it 'displays assignment controls for admins' do
      visit cluster_case_path(cluster, open_case, as: admin)
      assignment_select = find('#case-assignment').find('select')

      options = assignment_select.all('option').map(&:text)
      expect(options).to eq(['Nobody', 'A Scientist', '* A Scientist'])
    end

    it 'changes assigned user when assignee is selected' do
      open_case.reload  # generates case-creation email which we can then ignore
      emails.clear

      user = create(:admin, name: 'Jerry')

      visit cluster_case_path(cluster, open_case, as: admin)
      find('#case-assignment').select(user.name)
      click_button('Change assignment')

      expect(find('.alert-success')).to have_text "Support case #{open_case.display_id} updated."

      open_case.reload

      expect(open_case.assignee).to eq(user)
      expect(emails.count).to eq 1
      expect(emails[0].parts.first.body.raw_source).to have_text 'This case has now been assigned to Jerry'

    end

    context 'when a case has an assignee' do
      let(:assignee) { contact }
      it 'preselects the current assignee' do
        visit cluster_case_path(cluster,open_case, as: admin)
        assignment_select = find('#case-assignment').find('select')

        expect(assignment_select.value).to eq(contact.id.to_s)
      end

      it 'can remove assignee' do
        open_case.reload  # generates case-creation email which we can then ignore
        emails.clear

        visit cluster_case_path(cluster, open_case, as: admin)
        find('#case-assignment').select('Nobody')
        click_button('Change assignment')

        expect(find('.alert-success')).to have_text "Support case #{open_case.display_id} updated."

        open_case.reload

        expect(open_case.assignee).to be nil
        expect(emails.count).to eq 1
        expect(emails[0].parts.first.body.raw_source).to have_text 'This case is no longer assigned.'

      end
    end
  end

  describe 'Commenting' do

    context 'for open non-consultancy Case' do
      subject { create(:open_case, cluster: cluster, tier_level: 2) }

      it 'disables commenting for site contact' do
        visit cluster_case_path(cluster,subject, as: contact)

        expect do
          find(comment_form_class)
        end.to raise_error(Capybara::ElementNotFound)

        expect(find('.card.bg-light').text).to match 'Additional discussion is not available for this case'
      end

      it 'enables commenting for site contact if comments_enabled is true' do
        subject.comments_enabled = true
        subject.save

        visit cluster_case_path(cluster,subject, as: contact)

        fill_in 'case_comment_text', with: 'This is a test comment'
        click_button 'Add new comment'

        subject.reload

        expect(subject.case_comments.count).to be 1
        expect(find('.event-card').find('.card-body').text).to eq('This is a test comment')
        expect(find('.alert')).to have_text('New comment added')

      end

      it 'allows admin to enable commenting when disabled' do
        visit cluster_case_path(cluster,subject, as: admin)
        click_link 'Enable'

        subject.reload
        expect(subject.comments_enabled).to eq true
        expect(find('.alert-success')).to have_text "Commenting enabled for contacts on case #{subject.display_id}"
      end

      it 'allows admin to disable commenting when enabled' do
        subject.comments_enabled = true
        subject.save

        visit cluster_case_path(cluster,subject, as: admin)
        click_link 'Disable'

        subject.reload
        expect(subject.comments_enabled).to eq false
        expect(find('.alert-success')).to have_text "Commenting disabled for contacts on case #{subject.display_id}"
      end
    end

    it 'allows a comment to be added' do
      visit cluster_case_path(cluster,open_case, as: admin)

      fill_in 'case_comment_text', with: 'This is a test comment'
      click_button 'Add new comment'

      open_case.reload

      expect(open_case.case_comments.count).to be 1
      expect(find('.event-card').find('.card-body').text).to eq('This is a test comment')
      expect(find('.alert-success')).to have_text('New comment added')
    end

    it 'does not allow empty comments' do
      visit cluster_case_path(cluster,open_case, as: admin)

      fill_in 'case_comment_text', with: ''
      click_button 'Add new comment'

      open_case.reload

      expect(open_case.case_comments.count).to be 0
      expect(find('.alert-danger')).to have_text('Empty comments are not permitted')
    end

    %w(resolved closed).each do |state|
      context "for a #{state} case" do
        subject { create("#{state}_case".to_sym, cluster: cluster, tier_level: 3) }

        it 'does not allow commenting by site contact' do
          visit cluster_case_path(cluster,subject, as: contact)
          expect do
            find('textarea')
          end.to raise_error(Capybara::ElementNotFound)
        end

        it 'does not allow commenting by admin' do
          visit cluster_case_path(cluster,subject, as: admin)
          expect do
            find('textarea')
          end.to raise_error(Capybara::ElementNotFound)
        end

      end
    end

  end

  describe 'time logging' do

    let (:time_form_id) { '#case-time-form' }
    let (:time_form_submit_button) { 'Change time worked' }

    RSpec.shared_examples 'time display' do
      it 'correctly displays existing time in hours and minutes' do
        visit cluster_case_path(cluster,subject, as: admin)

        form = find(time_form_id)
        expect(form.find_field('time[hours]', disabled: :all).value).to eq "2"
        expect(form.find_field('time[minutes]', disabled: :all).value).to eq "17"
      end

      it 'doesn\'t show time worked to contacts' do
        visit cluster_case_path(cluster,subject, as: contact)
        expect { find(time_form_id) }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context 'for an open case' do
      subject do
        create(:open_case, cluster: cluster, time_worked: (2 * 60) + 17)
      end

      include_examples 'time display'

      it 'allows admins to set time worked' do
        visit cluster_case_path(cluster,subject, as: admin)

        fill_in 'time[hours]', with: '3'
        fill_in 'time[minutes]', with: '42'
        click_button time_form_submit_button

        subject.reload

        expect(subject.time_worked).to eq (3 * 60) + 42
      end

      it 'allows null values in time worked' do
        visit cluster_case_path(cluster,subject, as: admin)

        fill_in 'time[hours]', with: ''
        fill_in 'time[minutes]', with: '42'
        click_button time_form_submit_button

        subject.reload

        expect(subject.time_worked).to eq 42

        fill_in 'time[hours]', with: ''
        fill_in 'time[minutes]', with: ''
        click_button time_form_submit_button

        subject.reload

        expect(subject.time_worked).to eq nil

        fill_in 'time[hours]', with: '1'
        fill_in 'time[minutes]', with: ''
        click_button time_form_submit_button

        subject.reload

        expect(subject.time_worked).to eq 60
      end

    end

    context 'for a resolved case' do
      subject do
        create(:resolved_case, cluster: cluster, time_worked: (2 * 60) + 17)
      end

      include_examples 'time display'

      it 'does not allow time worked to be changed' do
        visit cluster_case_path(cluster,subject, as: admin)

        expect(find_field('time[hours]', disabled: true)).to be_disabled
        expect(find_field('time[minutes]', disabled: true)).to be_disabled
        expect(find(time_form_id)).not_to \
          have_button(time_form_submit_button, disabled: :any)
      end
    end
  end

  describe 'escalation' do
    let(:escalate_button_text) { 'Escalate' }

    context 'for open tier 2 case' do
      subject do
        create(:open_case, tier_level: 2, cluster: cluster)
      end

      it 'can be escalated using button' do
        visit cluster_case_path(cluster,subject, as: admin)

        expect do
          find_button escalate_button_text
        end.not_to raise_error

        click_button escalate_button_text

        # Using find(...).click instead of click_button waits for modal to appear
        find('#confirm-escalate-button').click

        subject.reload
        expect(subject.tier_level).to eq 3
      end

      it_behaves_like 'button is disabled for viewers' do
        let(:path) { cluster_case_path(subject.cluster, subject, as: user) }
        let(:button_text) { escalate_button_text }
        let(:disabled_button_title) do
          'As a viewer you cannot escalate a case'
        end
      end
    end

    RSpec.shared_examples 'for inapplicable cases' do
      it 'does not show escalate button' do
        visit cluster_case_path(cluster, subject, as: admin)

        expect do
          find_button escalate_button_text
        end.to raise_error(Capybara::ElementNotFound)
      end
    end

    context 'for open tier 3 case' do
      subject do
        create(:open_case, tier_level: 3, cluster: cluster)
      end

      it_behaves_like 'for inapplicable cases'
    end

    context 'for resolved tier 2 case' do
      subject do
        create(:resolved_case, tier_level: 2, cluster: cluster)
      end

      it_behaves_like 'for inapplicable cases'
    end

    context 'for closed tier 2 case' do
      subject do
        create(:closed_case, tier_level: 2, cluster: cluster)
      end

      it_behaves_like 'for inapplicable cases'
    end
  end

  describe 'maintenance window request' do

    RSpec.shared_examples 'does not show maintenance button' do
      it 'doesn\'t show maintenance button' do
        visit cluster_case_path(cluster, subject, as: user)
        expect do
          find('a', text: 'Request maintenance')
        end.to raise_error(Capybara::ElementNotFound)
      end
    end

    context 'for an open case' do
      subject { open_case }

      context 'as an admin' do
        let(:user) { admin }

        it 'shows button' do
          visit cluster_case_path(cluster,subject, as: user)

          request_link = find('a', text: 'Request maintenance')
          expect(request_link[:href]).to eq new_cluster_case_maintenance_path(cluster, open_case)
        end

        context 'as a contact' do
          let(:user) { contact }
          include_examples 'does not show maintenance button'
        end
      end
    end

    %w(resolved closed).each do |state|
      context "for a #{state} case" do
        subject do
          send("#{state}_case")
        end

        let(:user) { admin }

        include_examples 'does not show maintenance button'
      end
    end
  end

  describe 'applying requests' do
    subject do
      create(
        :case_with_change_motd_request,
        change_motd_request: request
      )
    end

    let(:request) { create(:change_motd_request, state: :unapplied) }

    let(:path) { cluster_case_path(subject.cluster, subject, as: user) }
    let(:apply_button_text) { 'Done' }
    let(:reapply_button_text) { 'Already applied' }

    def assert_button_successfully_applies(button_text)
      expect do
        click_button button_text
      end.to change { request.reload.transitions.length }.by(1)

      expect(request).to be_applied
      expect(current_path).to eq(cluster_case_path(subject.cluster, subject))
      expect(
        find('.alert')
      ).to have_text('The cluster has been updated to reflect this change.')
    end

    before :each do
      visit path
    end

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it 'has warning-styled button' do
        button = find_button(apply_button_text)
        expect(button['class']).to include('btn-warning')
      end

      it 'can use button to apply request' do
        assert_button_successfully_applies(apply_button_text)
      end

      context 'when request has already been applied' do
        let(:request) { create(:change_motd_request, state: :applied) }

        it 'has danger-styled button' do
          button = find_button(reapply_button_text)
          expect(button['class']).to include('btn-danger')
        end

        it 'can use button to re-apply request' do
          assert_button_successfully_applies(reapply_button_text)
        end
      end
    end

    context 'when user is contact' do
      let(:user) { create(:contact, site: subject.site) }

      it 'is not shown either button' do
        [apply_button_text, reapply_button_text].each do |button_text|
          expect(page).not_to have_button(button_text)
        end
      end
    end
  end

  describe 'redirection' do
    let (:kase) { create(:case, cluster: cluster) }
    let (:another_kase) { create(:case, cluster: another_cluster) }
    let (:another_site) { create(:site, name: 'Not My Site') }
    let (:another_cluster) { create(:cluster, site: another_site) }


    RSpec.shared_examples 'redirect examples' do
      it "redirects to the cluster dashboard case page from /cases/:id" do
        visit(cluster_case_path(cluster, kase, as: user))
        expect(current_path).to eq(cluster_case_path(kase.cluster, kase))
      end

      it 'correctly visits the case page for an associated case' do
        visit(cluster_case_path(cluster, kase, as: user))
        expect(page).to have_http_status(200)
      end

      it 'returns a 404 when visiting an unassociated case page' do
        visit(cluster_case_path(cluster, another_kase, as: user))
        expect(page).to have_http_status(404)
      end
    end

    context 'as contact' do
      let (:user) { contact }
      include_examples 'redirect examples'
    end

    context 'as admin' do
      let (:user) { admin }
      include_examples 'redirect examples'
    end
  end
end
