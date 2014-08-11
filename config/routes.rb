Rails.application.routes.draw do
  devise_for :users
  devise_for :devusers
  root to: "hiveapplication#login_page"

  resources :hiveapplication
  post "hiveapplication/sign_in"              , path: "sign_in"
  get "hiveapplication/verify"                , path: "verify"

  match "hiveapplication/login_page"          , path: "login_page"              , via: [:get, :post]
  match "hiveapplication/index"               , path: "index"                   , via: [:get, :post]
  match "hiveapplication/dev_portal"          , path: "dev_portal"              , via: [:get, :post]
  match "hiveapplication/application_list"    , path: "dev_portal"              , via: [:get, :post]
  match "hiveapplication/sign_up"             , path: "sign_up"                 , via: [:get, :post]
  match "hiveapplication/regenerate_api_key"  , path: "regenerate_api_key"      , via: [:get, :post]
  match "hiveapplication/delete_application"  , path: "delete_application"      , via: [:get, :post]
  match "hiveapplication/edit_application"    , path: "edit_application"        , via: [:get, :post]
  match "hiveapplication/add_application"     , path: "add_application"         , via: [:get, :post]
  match "hiveapplication/sign_up"             , path: "sign_up"                 , via: [:get, :post]
  match "hiveapplication/forget_password"     , path: "forget_password"         , via: [:get, :post]
  match "hiveapplication/reset_password"      , path: "reset_password"          , via: [:get, :post]
  match "hiveapplication/update_password"     , path: "update_password"         , via: [:get, :post]
  match "hiveapplication/edit_column"         , path:"edit_column"              , via: [:get, :post]
  match "hiveapplication/delete_additional_column", path:"delete_additional_column" , via: [:get, :post]
  match "hiveapplication/update_additional_column", path:"update_additional_column" , via: [:get, :post]
  match "hiveapplication/edit_additional_column",path:"edit_additional_column"  , via: [:get, :post]
  match "hiveapplication/create_additional_field",path:"create_additional_field", via: [:get,:post]

  #get "hiveapplication/sign_up", path: "sign_up"
  #post "hiveapplication/sign_up", path: "sign_up"

  #resources :topics
  #resources :posts
  #resources :users
  #resources :dev_users

  #get "sign_in", to: "hiveapplication#sign_in"

  namespace :api do
    match "downloaddata/initial_retrieve"           => "downloaddata#initial_retrieve"          , via: [:get, :post]
    match "downloaddata/retrieve_hiveapplications"  => "downloaddata#retrieve_hiveapplications" , via: [:get, :post]
    match "users/create_anonymous_user"             => "users#create_anonymous_user"            , via: [:get, :post]
    match "users/sign_up"                           => "users#sign_up"                          , via: [:get, :post]
    match "users/sign_in"                           => "users#sign_in"                          , via: [:get, :post]
    match "users/facebook_login"                    => "users#facebook_login"                   , via: [:get, :post]
    match "users/verify_user_account"               => "users#verify_user_account"              , via: [:get, :post]
    match "topics/create"                           => "topics#create"                          , via: [:get, :post]
    match "posts/create"                            => "posts#create"                           , via: [:get, :post]
    match "posts/retrieve_post"                     => "posts#retrieve_post"                    , via: [:get, :post]
    match "posts/post_liked"                        => "posts#post_liked"                       , via: [:get, :post]
    match "posts/post_offensive"                    => "posts#post_offensive"                   , via: [:get, :post]
    match "userpushtokens/create"                   => "userpushtokens#create"                  , via: [:get, :post]
    match "places/create"                           => "places#create"                          , via: [:get, :post]
    match "places/retrieve_places"                  => "places#retrieve_places"                 , via: [:get, :post]
    match "mytest/test"                             => "mytest#test"                            , via: [:get, :post]
    match "mytest/test2"                            => "mytest#test2"                           , via: [:get, :post]
    match "mytest/test3"                            => "mytest#test3"                           , via: [:get, :post]
    match "mytest/test4"                            => "mytest#test4"                           , via: [:get, :post]
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
