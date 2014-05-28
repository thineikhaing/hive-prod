Rails.application.routes.draw do
  devise_for :users
  devise_for :devusers
  root to: "hiveapplication#index"

  resources :hiveapplication
  post "hiveapplication/sign_in", path: "sign_in"
  get "hiveapplication/verify", path: "verify"

  match "hiveapplication/dev_portal"          , path: "dev_portal", via: [:get, :post]
  match "hiveapplication/application_list"    , path: "dev_portal", via: [:get, :post]
  match "hiveapplication/sign_up"             , path: "sign_up", via: [:get, :post]
  match "hiveapplication/regenerate_api_key"  ,path: "regenerate_api_key", via: [:get, :post]
  match "hiveapplication/delete_application"  ,path: "delete_application", via: [:get, :post]
  match "hiveapplication/edit_application"    ,path: "edit_application", via: [:get, :post]
  match "hiveapplication/add_application"    , path: "add_application", via: [:get, :post]
  match "hiveapplication/sign_up"             , path: "sign_up", via: [:get, :post]
  match "hiveapplication/forget_password"     , path: "forget_password", via: [:get, :post]
  match "hiveapplication/reset_password"      , path: "reset_password", via: [:get, :post]
  match "hiveapplication/update_password"     , path: "update_password", via: [:get, :post]

  #get "hiveapplication/sign_up", path: "sign_up"
  #post "hiveapplication/sign_up", path: "sign_up"

  #resources :topics
  #resources :posts
  #resources :users
  #resources :dev_users

  #get "sign_in", to: "hiveapplication#sign_in"

  namespace :api do
    match "mytest/test"             => "mytest#test"  , :via => :get
    match "mytest/test2"            => "mytest#test2" , :via => :get
    match "mytest/test3"            => "mytest#test3" , :via => :get
    match "mytest/test4"            => "mytest#test4" , :via => :get
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable dcco
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
