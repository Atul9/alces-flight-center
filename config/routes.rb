Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  mount RailsEmailPreview::Engine, at: 'emails' if Rails.env.development?

  get '/reset-password' => 'passwords#new', as: 'passwords'
  post '/reset-password' => 'passwords#create'

  # URL to complete password reset process. This will cause a user's password
  # to be changed (given the correct params), but `get` must be used as it will
  # be reached from an email.
  get '/reset-password/complete' => 'passwords#reset_complete'

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do
    root 'sites#index'
    resources :sites, only: [:show, :index] do
      resources :cases, only: [:new, :index]
    end

    resources :cases do
      member do
        post :request_maintenance_window
        post :end_maintenance_window
      end
    end

    resources :clusters do
      resources :maintenance_windows, only: :new
    end

    resources :components do
      resources :maintenance_windows, only: :new
    end

    resources :services do
      resources :maintenance_windows, only: :new
    end

    resources :maintenance_windows, only: :create do
      member do
        post :end
      end
    end

    resources :credit_charges, only: [:create, :update]

    # To display a working link to sign users out of the admin dashboard,
    # rails-admin expects a `logout_path` route helper to exist which will sign
    # them out; this declaration defines this.
    delete :logout, to: 'clearance/sessions#destroy'
  end

  constraints Clearance::Constraints::SignedIn.new do
    root 'sites#show'
    delete '/sign_out' => 'clearance/sessions#destroy', as: 'sign_out'

    resources :cases, only: [:new, :index, :create] do
      member do
        post :archive
        post :restore
      end
    end

    resources :clusters, only: :show do
      resources :cases, only: :new
      resources :consultancy, only: :new
    end

    resources :components, only: :show do
      resources :cases, only: :new
      resources :consultancy, only: :new
    end

    resources :services, only: :show do
      resources :cases, only: :new
      resources :consultancy, only: :new
    end

    resources :maintenance_windows do
      member do
        post :confirm
      end
    end
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'clearance/sessions#new', as: 'sign_in'
    post '/' => 'clearance/sessions#create', as: 'session'
  end
end
