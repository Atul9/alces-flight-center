require 'resque/server'

class NoteFlavourConstraint
  def initialize(admin:)
    @admin = admin
  end

  def matches?(request)
    flavour = request.env['action_dispatch.request.path_parameters'][:flavour]
    if @admin
      Note::FLAVOURS.include?(flavour)
    else
      flavour == 'customer'
    end
  end
end

Rails.application.routes.draw do

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  asset_record_alias = 'asset-record'
  component_expansions_alias = 'expansions'
  component_groups_alias = 'component-groups'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  mount RailsEmailPreview::Engine, at: 'emails' if Rails.env.development?

  asset_record_view = Proc.new {
    resource :asset_record, path: asset_record_alias, only: :show
  }
  asset_record_form = Proc.new do
    resource :asset_record, path: asset_record_alias, only: [:edit, :update]
  end

  logs = Proc.new do
    resources :logs, only: :index
  end
  admin_logs = Proc.new do
    resources :logs, only: :create do
      collection do
        post 'preview' => 'logs#preview'
        post 'write' => 'logs#write'
      end
    end
  end
  notes = Proc.new do |admin|
    constraints NoteFlavourConstraint.new(admin: admin) do
      prefix = admin ? '' : 'prevent_named_route_clash_'
      resources :notes, param: :flavour, except: [:new, :create, :index] do
        collection do
          post ':flavour' => 'notes#create', as: prefix
        end
        member do
          post 'preview' => 'notes#preview'
          post 'write' => 'notes#write'
        end
      end
    end
  end

  maintenance_windows = Proc.new do
    resources :maintenance_windows, path: :maintenance, only: :index
  end

  cases = Proc.new do |**params, &block|
    params[:only] = Array.wrap(params[:only]).concat [:index]
    resources :cases, **params do
      collection do
        get :resolved
      end
      block.call if block
    end
  end

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do

    mount Resque::Server, at: '/resque'

    root 'sites#index'
    resources :sites, only: [:show, :index] do
      cases.call(only: [:index, :new])
      resource :terminal_services, only: [:show]
    end

    cases.call(only: []) do
      # Actions on cases belong here. Typically these will end with a redirect
      # to cluster_case_path or similar.
      member do
        post :resolve  # Only admins may resolve a case
        post :close  # Only admins may close a case
        post :assign  # Only admins may (re)assign a case
        post :set_time
        post :set_commenting
      end
      resource :change_request, only: [:create, :update], path: 'change-request' do
        member do
          post :propose
          post :handover
        end
      end

      resource :case_associations, only: [:update], as: 'update_associations', path: 'associations'
    end

    resources :change_motd_requests, only: [] do
      member do
        post :apply
      end
    end

    resources :clusters, only: [] do
      cases.call(only: []) do
        # Admin-only pages relating to cases belong here.
        resource :change_request, only: [:new, :edit], path: 'change-request'
        resource :case_associations, only: [:edit], as: 'associations', path: 'associations'
        resource :maintenance_windows, only: [:new, :create], as: 'maintenance', path: 'maintenance'
      end
      admin_logs.call
      notes.call(true)
      post :deposit
    end

    resources :components, only: []  do
      resource :component_expansion,
               path: component_expansions_alias,
               only: [:edit, :update, :create]
      asset_record_form.call
      admin_logs.call
    end

    resources :component_expansions, only: [:destroy]

    resources :component_groups, path: component_groups_alias, only: [] do
      asset_record_form.call
    end

    resources :maintenance_windows, path: :maintenance, only: [] do
      member do
        post :cancel
        post :end
        post :extend
      end
    end

    # To display a working link to sign users out of the admin dashboard,
    # rails-admin expects a `logout_path` route helper to exist which will sign
    # them out; this declaration defines this.
    delete :logout, to: 'sso_sessions#destroy'

    # Support legacy case URLs
    get '/sites/:site_id/cases/:id', to: 'cases#redirect_to_canonical_path'
  end

  constraints Clearance::Constraints::SignedIn.new do
    root 'sites#show'
    delete '/sign_out' => 'sso_sessions#destroy', as: 'sign_out'  # Keeping this one around as it's correctly coupled to SSO

    cases.call(only: [:new, :create, :index]) do
      # Actions for cases, for admins and site users, belong here.
      member do
        post :escalate
      end

      resource :change_request, only: [:show], path: 'change-request' do
        member do
          post :authorise
          post :decline
          post :complete
        end
      end

      resources :case_comments, only: :create do
        collection do
          post :preview
          post :write
        end
      end
    end

    resources :clusters, only: :show do
      cases.call(only: [:show, :create, :index, :new]) do
        # Pages relating to cases, for both admins and site users, belong here.
         resource :change_request, only: [:show], path: 'change-request'
      end
      resources :services, only: :index
      maintenance_windows.call
      resources :components, only: :index
      logs.call
      get :documents
      notes.call(false)
      get '/credit-usage(/:start_date)', to: 'clusters#credit_usage', as: :credit_usage
    end

    resources :components, only: :show do
      maintenance_windows.call
      resources :component_expansions,
                path: component_expansions_alias,
                only: :index
      asset_record_view.call
      logs.call
    end

    resources :component_groups, path: component_groups_alias, only: [] do
      get '/', controller: :components, action: :index
      resources :components, only: :index
      asset_record_view.call
      maintenance_windows.call
    end

    resources :services, only: :show do
      maintenance_windows.call
    end

    resources :maintenance_windows, path: :maintenance, only: [] do
      member do
        get :confirm
        patch :confirm, to: 'maintenance_windows#confirm_submit'
        post :reject
      end
    end

    resource :terminal_services, only: [:show]
    resource :users, only: [:show]
    resources :topics, only: [:index]

    # Support legacy case URLs
    get '/cases/:id', to: 'cases#redirect_to_canonical_path'
    get '/services/:service_id/cases/:id', to: 'cases#redirect_to_canonical_path'
    get '/components/:component_id/cases/:id', to: 'cases#redirect_to_canonical_path'
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'sso_sessions#new', as: 'sign_in'
    resource :users, only: [:show]
    resources :topics, only: [:index]
  end

  # Routes defined here are only defined/used in certain tests which need
  # access to special routes/controllers.
  if Rails.env.test?
    resource :request_test, only: :show
  end
end
