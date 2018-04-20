require 'rails_helper'

RSpec.describe 'Case mailer', :type => :mailer do

  let :site do
    create(:site)
  end

  let :requestor do
    create(:user, name: 'Some User', email: 'someuser@somecluster.com', site: site)
  end

  let :another_user do
    create(:user, site: site, email: 'another.user@somecluster.com' )
  end

  let :additional_contact do
    create(
        :additional_contact,
        site: site,
        email: 'mailing-list@somecluster.com'
    )
  end

  let :issue do
    create(
        :issue,
        name: 'Crashed node',
        requires_component: requires_component,
        requires_service: requires_service,
        category: category
    )
  end

  let(:requires_component) { true }
  let(:requires_service) { true }

  let(:category) { create(:category, name: 'Hardware issue') }
  let(:cluster) { create(:cluster, site: site, name: 'somecluster') }
  let(:component) { create(:component, name: 'node01', cluster: cluster) }
  let(:service) { create(:service, name: 'Some service', cluster: cluster) }

  let(:kase) {
    create(
        :case,
        rt_ticket_id: 1138,
        created_at: Time.now,
        cluster: cluster,
        issue: issue,
        component: component,
        service: service,
        user: requestor,
        subject: 'my_subject',
        details: <<-EOF.strip_heredoc
          Oh no
          my node
          is broken
    EOF
    )
  }

  before(:each) do
    site.users = [requestor, another_user]
    site.additional_contacts = [additional_contact]
  end

  it 'sends an email on case creation' do
    mail = CaseMailer.new_case(kase)
    expect(mail.subject).to eq "[helpdesk.alces-software.com #1138] somecluster: my_subject [#{kase.token}]"

    expect(mail.to).to eq nil
    expect(mail.cc).to eq %w(another.user@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to eq(['tickets@alces-software.com'])

    expected_body = <<EOF
Requestor: Some User
Cluster: somecluster
Category: Hardware issue
Issue: Crashed node
Associated component: node01
Associated service: Some service
Details: Oh no
 my node
 is broken
EOF

    expect(mail.body.encoded).to match(expected_body)
  end

  context 'when no associated component' do
    let(:requires_component) { false }
    let(:component) { nil }

    it 'does not include corresponding line in email text' do
      mail = CaseMailer.new_case(kase)
      expect(mail.body.encoded).not_to match('Associated component:')
    end

  end

  context 'when no associated service' do
    let(:requires_service) { false }
    let(:service) { nil }

    it 'does not include corresponding line in email text' do
      mail = CaseMailer.new_case(kase)
      expect(mail.body.encoded).not_to match('Associated service:')
    end

  end

  it 'sends an email on case comment being added' do
    comment = create(:case_comment,
      case: kase,
      user: another_user,
      text: 'I can haz comment'
    )

    mail = CaseMailer.comment(comment)

    expect(mail.to).to eq nil
    expect(mail.cc).to eq %w(someuser@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to eq(['tickets@alces-software.com'])

    expect(mail.body.encoded).to match('I can haz comment')
  end

end