require 'rails_helper'

RSpec.describe ApplicationDecorator do
  describe '#cluster_part_icons' do
    describe 'maintenance icons' do
      subject { component.decorate.cluster_part_icons }
      let(:component) { create(:component, name: 'mycomponent') }

      it 'includes correct icon when has requested maintenance window' do
        window = create(:requested_maintenance_window, components: [component])
        display_id = window.case.display_id

        expect(subject).to include(
          h.icon(
            'wrench',
            inline: true,
            class: 'faded-icon',
            title: "Maintenance has been requested for #{component.name} for case #{display_id}"
          )
        )
      end

      it 'includes correct icon when has confirmed maintenance window' do
        window = create(:confirmed_maintenance_window, components: [component])
        display_id = window.case.display_id

        expect(subject).to include(
          h.icon(
            'wrench',
            inline: true,
            class: 'faded-icon',
            title: "Maintenance is scheduled for #{component.name} for case #{display_id}"
          )
        )
      end

      it 'includes correct icon when has in progress maintenance window' do
        window = create(:maintenance_window, state: :started, components: [component])
        display_id = window.case.display_id

        expect(subject).to include(
          h.icon(
            'wrench',
            inline: true,
            title: "#{component.name} currently under maintenance for case #{display_id}"
          )
        )
      end

      it 'gives nothing when no maintenance windows' do
        expect(subject).to be_empty
      end

      it 'gives nothing when only has finished maintenance window' do
        create(:ended_maintenance_window, components: [component])
        expect(subject).to be_empty
      end

      it 'includes icon for every unfinished maintenance window' do
        create(:requested_maintenance_window, components: [component])
        create(:maintenance_window, state: :started, components: [component])
        create(:ended_maintenance_window, components: [component])

        expect(subject).to match(/<i .*<i /)
      end
    end

    describe 'internal icon' do
      it 'includes internal icon when internal' do
        part = create(:service, internal: true)

        expect(part.decorate.cluster_part_icons).to include(
          h.image_tag(
            'flight-icon',
            alt: 'Service for internal Alces usage',
            title: 'Service for internal Alces usage'
          )
        )
      end

      it 'does not include internal icon when not internal' do
        part = create(:component, internal: false)

        expect(part.decorate.cluster_part_icons).to be_empty
      end

      it 'does not include internal icon when does not have internal field' do
        cluster = create(:cluster)

        expect(cluster.decorate.cluster_part_icons).to be_empty
      end
    end
  end

  describe 'event cards' do

      Dir[File.join(Rails.root, 'app/decorators/*.rb')].each { |f| load f }

      ApplicationDecorator.descendants.each do |decorator|
        if decorator.instance_methods.include? :event_card
          context decorator.name do
            it 'renders event card' do
              obj = create(decorator.object_class_name.underscore.to_sym)
              obj.decorate.event_card
            end
          end
        end
      end

  end
end
