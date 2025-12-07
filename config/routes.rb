Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      devise_for :users, path: "users", path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "signup"
      },
      controllers: {
        sessions: "api/v1/users/sessions",
        registrations: "api/v1/users/registrations"
      }

      # Current user endpoint
      get "users/me", to: "users/users#show", as: :current_user

      # Visitors endpoints
      get "visitors", to: "visitors#index"
      get "visitors/logs", to: "visitors#logs"
      get "visitors/analytics", to: "visitors#analytics"
      post "visitors/check-in", to: "visitors#check_in"
      post "visitors/checkout", to: "visitors#checkout"
      get "visitors/check-ins/latest", to: "visitors#latest_check_ins"
      get "visitors/check-outs/latest", to: "visitors#latest_check_outs"

      # Staff members endpoints
      get "staff-members", to: "staff_members#index"
    end
  end
end
