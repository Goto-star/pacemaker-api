Rails.application.routes.draw do
  get "auth/:provider/callback" => "auth/omniauth_callbacks#create"
  post "auth/development/login" => "auth/development_logins#create"
  get "auth/failure" => "auth/omniauth_callbacks#failure"

  get "me" => "me#show", as: :me

  get "today_plan" => "today_plan#show", as: :today_plan

  resources :materials, only: %i[index create update destroy] do
    resources :study_units, only: %i[index create update destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  get "health" => "health#show", as: :health_check

  root "health#show"
end
