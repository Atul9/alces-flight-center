require 'rails_helper'

# Shared examples for a Case-part relationship, where a part:
# - is a class with a factory identified by `part_name`;
# - has a `support_type`;
# - has a `cluster`.
RSpec.shared_examples 'associated Cluster part validation' do |part_name|
  context "when issue requires #{part_name}" do
    before :each do
      requires_part_name = "requires_#{part_name}".to_sym
      issue_attributes.merge!(requires_part_name => true)
    end

    let(:cluster) { create(:cluster) }

    context "when not associated with #{part_name}" do
      it 'should be invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to include(part_name => [/requires a #{part_name}/])
      end
    end

    context "when associated with #{part_name} that is part of associated cluster" do
      let(:part) { create(part_name, cluster: cluster) }
      it { is_expected.to be_valid }
    end

    context "when associated with #{part_name} that is not part of associated cluster" do
      let(:part) { create(part_name, cluster: create(:cluster)) }
      it 'should be invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to include(part_name => [/not part of given cluster/])
      end
    end
  end
end

RSpec.describe Case, type: :model do
  describe '#valid?' do
    subject do
      attributes = {
        issue: issue,
        cluster: cluster,
        components: component ? [component] : [],
        services: service ? [service] : [],
        # Specify consultancy Tier explicitly here, to avoid triggering
        # validations from AvailableSupportValidator which would get in the
        # way.
        tier_level: 3,
      }

      # If `part` is set, appropriately add Case attribute depending on `part`
      # class.
      if part
        case part
        when Component
          attributes[:components] << part
        when Service
          attributes[:services] << part
        else
          raise "Unknown part class: #{part.class}"
        end
      end

      build(:case, **attributes)
    end

    let(:cluster) { create(:cluster) }
    let(:component) { nil }
    let(:service) { nil }
    let(:part) { nil }

    let(:issue) { create(:issue, **issue_attributes) }
    let(:issue_attributes) { attributes_for(:issue) }

    include_examples 'associated Cluster part validation', :component
    include_examples 'associated Cluster part validation', :service

    context 'when issue does not require component or service' do
      before :each do
        issue_attributes.merge!(
          requires_component: false,
          requires_service: false
        )
      end

      context 'when not associated with component or service' do
        it { is_expected.to be_valid }
      end

      context 'when associated with component' do
        let(:component) { create(:component) }
        it { is_expected.to be_valid }
      end

      context 'when associated with service' do
        let(:service) { create(:service) }
        it { is_expected.to be_valid }
      end
    end

    context "when issue requires service of particular type" do
      let :issue do
        create(:issue, requires_service: true, service_type: service_type)
      end

      let :service_type do
        create(:service_type, name: 'File System')
      end

      context 'when associated with service of that type' do
        let :service do
          create(:service, cluster: cluster, service_type: service_type)
        end

        it { is_expected.to be_valid }
      end

      context 'when associated with service of a different type' do
        let :service do
          create(
            :service,
            cluster: cluster,
            service_type: create(:service_type, name: 'User Management')
          )
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to match(
            case: [/for issue.*must be.*File System.*but not given one/]
          )
        end
      end
    end
  end
end
