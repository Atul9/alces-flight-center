Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  # To display a working link to sign users out of the admin dashboard,
  # rails-admin expects a `logout_path` route helper to exist which will sign
  # them out; this declaration defines this.
  delete :logout, to: 'clearance/sessions#destroy'

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do
    root 'home#admin_landing'
  end

  constraints Clearance::Constraints::SignedIn.new do
    root 'cases#index'
    resources :cases, except: [:destroy]
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'home#signed_out'
  end
end
