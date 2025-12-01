Rails.application.routes.draw do
  # Authentication routes
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  # Dashboard (protected)
  get "dashboard", to: "dashboard#index"

  # Landing pages (public)
  get "landing/index"
  get "landing/sasha"
  get "landing/fitbot", to: "landing#looser_vibe_coder"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "landing#index"
end
