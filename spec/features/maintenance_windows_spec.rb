require 'rails_helper'

RSpec.feature "Maintenance windows", type: :feature do
  context 'when user is an admin' do
    let :user { create(:admin) }

    it 'can switch a Case to/from under maintenance' do
      support_case = create(:case)

      visit site_cases_path(support_case.site, as: user)

      start_link_path = start_maintenance_window_case_path(support_case.id)
      end_link_path = end_maintenance_window_case_path(support_case.id)

      start_link = page.find_link(href: start_link_path)
      expect(start_link).to have_css('.fa-wrench.interactive-icon')
      start_link.click
      expect(support_case).to be_under_maintenance
      expect(page).not_to have_link(href: start_link_path)

      end_link = page.find_link(href: end_link_path)
      expect(end_link).to have_css('.fa-heartbeat.interactive-icon')
      end_link.click
      expect(support_case).not_to be_under_maintenance
      expect(page).not_to have_link(href: end_link_path)
    end
  end
end
