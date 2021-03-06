
require 'rails_helper'

RSpec.describe 'cluster tabs', type: :feature do
  let(:cluster) { create(:cluster) }

  let(:tabs) { page.find('ul.nav-tabs') }
  let(:maintenance_tab) { tabs.find('li', text: /Maintenance/) }
  let(:documents_tab) { tabs.find('li', text: /Documents/) }
  let(:notes_tab) { tabs.find('li', text: /Notes/) }
  let(:user) { create(:contact, site: cluster.site) }

  context 'when visiting the cluster page' do

    subject { cluster }

    before(:each) {
      visit cluster_path(subject, as: user)
    }

    context 'with an admin user' do
      let(:user) { create(:admin) }

      it 'has a link to the existing maintenance' do
        path = cluster_maintenance_windows_path(cluster)
        expect(maintenance_tab).to have_link(href: path)
      end

      it 'does not have a Documents tab' do
        expect do
          documents_tab
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'has a dropdown menu for notes tab' do
        expect(notes_tab).to match_css('.dropdown')
        expect(notes_tab.first('div')).to match_css('.dropdown-menu')
      end

      it 'has a link to the engineering notes' do
        path = cluster_note_path(cluster, flavour: 'engineering')
        expect(notes_tab).to have_link(href: path)
      end

      it 'has a link to the customer notes' do
        path = cluster_note_path(cluster, flavour: 'customer')
        expect(notes_tab).to have_link(href: path)
      end

    end

    context 'with a contact user' do

      it 'has a link to the existing maintenance' do
        path = cluster_maintenance_windows_path(cluster)
        expect(maintenance_tab).to have_link(href: path)
      end

      it 'does not have a Documents tab' do
        expect do
          documents_tab
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'does not have dropdown menu for notes tab' do
        expect(notes_tab).not_to match_css('.dropdown')
      end

      it 'has a link to the customer notes' do
        path = cluster_note_path(cluster, flavour: 'customer')
        expect(notes_tab).to have_link(href: path)
      end
    end

    context 'for a cluster with documents' do
      subject do
        cluster.tap do |c|
          allow_any_instance_of(Cluster).to receive(:documents).and_return([
             Cluster::DocumentsRetriever::Document.new(
                 'Fake Document',
                 'http://www.example.com')
          ])
        end
      end

      context 'as an admin' do
        let(:user) { create(:admin) }
        it 'shows a documents tab' do
          expect do
            documents_tab
          end.not_to raise_error
        end
      end

      context 'as a contact' do
        it 'shows a documents tab' do
          expect do
            documents_tab
          end.not_to raise_error
        end
      end
    end
  end

end
