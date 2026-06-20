Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "health" => "health#show", as: :health_check

  root "health#show"
end
