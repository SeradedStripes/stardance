Raffle::Engine.routes.draw do
  root to: "dashboard#show"
  get "dashboard", to: "dashboard#show", as: :dashboard

  # GitHub OAuth. The request phase (/auth/github) is handled by the OmniAuth
  # middleware; this is the callback the provider redirects back to.
  match "auth/github/callback", to: "sessions#create", via: [ :get, :post ]
  get "auth/failure", to: "sessions#failure"
  delete "logout", to: "sessions#destroy", as: :logout

  if Rails.env.development? || Rails.env.test?
    get "dev_login(/:handle)", to: "sessions#dev_login", as: :dev_login
    post "dev/referrals", to: "dashboard#dev_referrals", as: :dev_referrals
  end

  # Terminal catch-all: an unmatched path in a mounted engine cascades
  # (X-Cascade: pass) back to the platform's routes, so without this the
  # raffle host would serve platform pages like /home. The engine owns its
  # host outright — anything it doesn't define is a 404.
  match "*path", to: "application#not_found", via: :all, format: false
end
