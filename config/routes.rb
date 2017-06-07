Rails.application.routes.draw do
  root 'top#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  devise_for :users
  get 'tweets' => 'tweets#index', :as => :tweets
  get 'tweets/:id' => 'tweets#show', :as => :tweet
end
