Rails.application.routes.draw do
  get "auth/:provider/callback" => "auth/omniauth_callbacks#create"
  get "auth/failure" => "auth/omniauth_callbacks#failure"

  get "me" => "me#show", as: :me

  get "up" => "rails/health#show", as: :rails_health_check

  get "health" => "health#show", as: :health_check

  root "health#show"
end
