Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :ingredients, only: [ :index ]
      resources :categories, only: [ :index ]
      resources :pantry_items, only: %i[index create destroy], path: "pantry-items"
      resources :recipe_matches, only: [ :create ], path: "recipe-matches"
      resources :recipes, only: [ :show ]
    end
  end
end
