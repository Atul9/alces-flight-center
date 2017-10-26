require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  describe 'GET #new' do
    let :site { create(:site) }
    let :user { create(:contact, site: site) }
    let! :first_cluster { create(:cluster, site: site, name: 'First cluster') }
    let! :second_cluster { create(:cluster, site: site, name: 'Second cluster') }

    before :each { sign_in_as(user) }

    context 'from top-level route' do
      it 'assigns all site clusters to @clusters' do
        get :new
        expect(assigns(:clusters)).to eq([first_cluster, second_cluster])
      end
    end

    context 'from cluster-level route' do
      it 'assigns just given cluster to @clusters' do
        get :new, params: { cluster_id: first_cluster.id }
        expect(assigns(:clusters)).to eq([first_cluster])
      end

      it 'gives 404 if cluster does not belong to user site' do
        another_cluster = create(:cluster)
        expect do
          get :new, params: { cluster_id: another_cluster.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context 'from component-level route' do
      let :component { create(:component, cluster: first_cluster) }

      it "assigns just given component's cluster to @clusters" do
        get :new, params: { component_id: component.id }
        expect(assigns(:clusters)).to eq([first_cluster])
      end

      it 'assigns given component to @single_component' do
        get :new, params: { component_id: component.id }
        expect(assigns(:single_component)).to eq(component)
      end

      it 'gives 404 if component does not belong to user site' do
        another_component = create(:component)
        expect do
          get :new, params: { component_id: another_component.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end
end