Rails.application.routes.draw do

  resources :sg_accident_histories
  resources :privacy_policies
  resources :user_fav_locations
  resources :lookups
  #resources :place_types
  resources :route_logs
  get 'carmic' => 'carmic#index', as: 'carmic'


  devise_for :users
  devise_for :devusers
  root to: "hiveapplication#login_page"

  resources :hiveapplication
  resources :car_action_logs
  post "hiveapplication/sign_in"              , path: "sign_in"
  get "hiveapplication/verify"                , path: "verify"

  match "hiveapplication/login_page"          , path: "login_page"                , via: [:get, :post]
  match "hiveapplication/index"               , path: "index"                     , via: [:get, :post]
  match "hiveapplication/dev_portal"          , path: "dev_portal"                , via: [:get, :post]
  match "hiveapplication/application_list"    , path: "dev_portal"                , via: [:get, :post]
  match "hiveapplication/sign_up"             , path: "sign_up"                   , via: [:get, :post]
  match "hiveapplication/regenerate_api_key"  , path: "regenerate_api_key"        , via: [:get, :post]
  match "hiveapplication/delete_application"  , path: "delete_application"        , via: [:get, :post]
  match "hiveapplication/edit_application"    , path: "edit_application"          , via: [:get, :post]
  match "hiveapplication/add_application"     , path: "add_application"           , via: [:get, :post]
  match "hiveapplication/sign_up"             , path: "sign_up"                   , via: [:get, :post]

  match "hiveapplication/verify_signup"       , path: "verify_signup"             , via: [:get, :post]

  match "hiveapplication/forget_password"     , path: "forget_password"           , via: [:get, :post]
  match "hiveapplication/reset_password"      , path: "reset_password"          , via: [:get, :post]
  match "hiveapplication/update_password"     , path: "update_password"         , via: [:get, :post]
  match "hiveapplication/edit_column"         , path:"edit_column"              , via: [:get, :post]
  match "hiveapplication/delete_additional_column", path:"delete_additional_column" , via: [:get, :post]
  match "hiveapplication/update_additional_column", path:"update_additional_column" , via: [:get, :post]
  match "hiveapplication/edit_additional_column",path:"edit_additional_column"  , via: [:get, :post]
  match "hiveapplication/create_additional_field",path:"create_additional_field", via: [:get,:post]
  match "hiveapplication/clear_columns_changes", path:"clear_columns_changes"   , via: [:get,:post]
  match "hiveapplication/save_columns_changes" , path:"save_columns_changes"    , via: [:get,:post]
  match "hiveapplication/edit_topic_post"      , path:"edit_topic_post"         , via: [:get,:post]
  match "hiveapplication/delete_topic"         , path:"delete_topic"            , via: [:get,:post]
  match "hiveapplication/delete_post"          , path:"delete_post"              , via: [:get,:post]
  match "hiveapplication/edit_topic"           , path:"edit_topic"              , via: [:get,:post]
  match "hiveapplication/edit_post"            , path:"edit_post"               , via: [:get,:post]
  match "hiveapplication/users"               , path:"users"               , via: [:get,:post]
  get 'hiveapplication/user_accounts/:id' => 'hiveapplication#user_accounts', :as => :user_accounts

  match "carmic/create_post"                   , path:"create_post"             , via: [:get,:post]
  match "carmic/singup"                       , path:"singup"                    , via: [:get,:post]
  match "carmic/login"                        , path:"login"                    , via: [:get,:post]
  match "carmic/camic_reset_pwd"               , path:"camic_reset_pwd"                  , via: [:get,:post]
  get "carmic/logout"                , path: "logout"

  match "carmic/create_post"        , path:  "create_post"     , via: [:get,:post]

  #get "hiveapplication/sign_up", path: "sign_up"
  #post "hiveapplication/sign_up", path: "sign_up"
  resources :places
  #resources :topics
  #resources :posts
  #resources :users
  #resources :dev_users

  #get "sign_in", to: "hiveapplication#sign_in"

  namespace :api do

    match "socal/create_event"                      => "socal#create_event"                     , via: [:get, :post]
    match "socal/retrieve_invitation_code"          => "socal#retrieve_invitation_code"         , via: [:get, :post]
    match "socal/retrieve_event"                    => "socal#retrieve_event"                   , via: [:get, :post]
    match "socal/create_post"                       => "socal#create_post"                      , via: [:get, :post]
    match "socal/create_user"                       => "socal#create_user"                      , via: [:get, :post]
    match "socal/download_posts"                    => "socal#download_posts"                   , via: [:get, :post]
    match "socal/topic_state"                       => "socal#topic_state"                      , via: [:get, :post]
    match "socal/retrieve_popular_date"             => "socal#retrieve_popular_date"            , via: [:get, :post]
    match "socal/vote_date"                         => "socal#vote_date"                        , via: [:get, :post]
    match "socal/get_suggesteddates"                => "socal#get_suggesteddates"               , via: [:get, :post]
    match "socal/confirm_dates"                     => "socal#confirm_dates"                    , via: [:get, :post]
    match "socal/mvc_suggesteddate"                 => "socal#mvc_suggesteddate"                , via: [:get, :post]
    match "socal/update_topic"                      => "socal#update_topic"                     , via: [:get, :post]

    match "hiveweb/get_all_topics_for_web"          => "hiveweb#get_all_topics_for_web"         , via: [:get, :post]
    match "hiveweb/get_all_posts_for_web"           => "hiveweb#get_all_posts_for_web"          , via: [:get, :post]
    match "hiveweb/create_post"                     => "hiveweb#create_post"                    , via: [:get, :post]
    match "hiveweb/get_all_topics_for_place"        => "hiveweb#get_all_topics_for_place"       , via: [:get, :post]
    match "hiveweb/map_view"                        => "hiveweb#map_view"                       , via: [:get, :post]
    match "hiveweb/popular_topic"                   => "hiveweb#popular_topic"                  , via: [:get, :post]
    match "hiveweb/sign_in"                         => "hiveweb#sign_in"                        , via: [:get, :post]
    match "hiveweb/sign_up"                         => "hiveweb#sign_up"                        , via: [:get, :post]


    match "hiveweb/get_topics_for_hive"             => "hiveweb#get_topics_for_hive"            , via: [:get, :post]
    match "hiveweb/get_topics_for_mealbox"          => "hiveweb#get_topics_for_mealbox"         , via: [:get, :post]
    match "hiveweb/get_topics_for_car"              => "hiveweb#get_topics_for_car"             , via: [:get, :post]
    match "hiveweb/get_topics_by_tag"               => "hiveweb#get_topics_by_tag"              , via: [:get, :post]


    match "downloaddata/initial_retrieve"           => "downloaddata#initial_retrieve"          , via: [:get, :post]
    match "downloaddata/retrieve_hiveapplications"  => "downloaddata#retrieve_hiveapplications" , via: [:get, :post]
    match "downloaddata/retrieve_users"             => "downloaddata#retrieve_users"            , via: [:get, :post]
    match "downloaddata/search_database"            => "downloaddata#search_database"           , via: [:get, :post]
    match "downloaddata/retrieve_topics_by_app_key" => "downloaddata#retrieve_topics_by_app_key", via: [:get, :post]
    match "downloaddata/background_retrieve"        => "downloaddata#background_retrieve"       , via: [:get, :post]
    match "downloaddata/retrieve_history"           => "downloaddata#retrieve_history"          , via: [:get, :post]
    match "downloaddata/latest_history"             => "downloaddata#latest_history"            , via: [:get, :post]
    match "downloaddata/posts_retrieve"             => "downloaddata#posts_retrieve"            , via: [:get, :post]
    match "downloaddata/retrieve_posts_in_range"    => "downloaddata#retrieve_posts_in_range"   , via: [:get, :post]
    match "downloaddata/segmented_posts_retrieve"   => "downloaddata#segmented_posts_retrieve"  , via: [:get, :post]
    match "downloaddata/retrieve_posts_history"     => "downloaddata#retrieve_posts_history"    , via: [:get, :post]
    match "downloaddata/posts_retrieve_for_user"    => "downloaddata#posts_retrieve_for_user"   , via: [:get, :post]

    match "downloaddata/retrieve_carmic_user"       => "downloaddata#retrieve_carmic_user"      , via: [:get, :post]

    match "downloaddata/incident_and_breakdown" => "downloaddata#incident_and_breakdown"   , via: [:get, :post]

    match "users/create_anonymous_user"             => "users#create_anonymous_user"            , via: [:get, :post]
    match "users/sign_up"                           => "users#sign_up"                          , via: [:get, :post]
    match "users/sign_in"                           => "users#sign_in"                          , via: [:get, :post]
    match "users/juice_sign_in"                     => "users#juice_sign_in"                    , via: [:get, :post]
    match "users/facebook_login"                    => "users#facebook_login"                   , via: [:get, :post]
    match "users/verify_user_account"               => "users#verify_user_account"              , via: [:get, :post]
    match "users/user_info"                         => "users#user_info"                        , via: [:get, :post]
    match "users/favourite_user"                    => "users#favourite_user"                   , via: [:get, :post]
    match "users/block_user"                        => "users#block_user"                       , via: [:get, :post]
    match "users/flare_mode"                        => "users#flare_mode"                       , via: [:get, :post]
    match "users/user_action_logs"                  => "users#user_action_logs"                 , via: [:get, :post]
    match "users/facebook_friends"                  => "users#facebook_friends"                 , via: [:get, :post]
    match "users/check_in"                          => "users#check_in"                         , via: [:get, :post]
    match "users/register_apn"                      => "users#register_apn"                     , via: [:get, :post]
    match "users/edit_profile"                      => "users#edit_profile"                     , via: [:get, :post]
    match "users/update_carmmunicate_user"          => "users#update_carmmunicate_user"         , via: [:get, :post]
    match "users/status"                            => "users#status"                           , via: [:get, :post]
    match "users/regenerate_username"               => "users#regenerate_username"              , via: [:get, :post]
    match "users/create_incident_history"           => "users#create_incident_history"          , via: [:get, :post]
    match "users/check_hive_user"                   => "users#check_hive_user"                  , via: [:get, :post]
    match "users/get_user_avatar"                   => "users#get_user_avatar"                  , via: [:get, :post]
    match "users/save_user_fav_location"            => "users#save_user_fav_location"           , via: [:get, :post]
    match "users/get_user_fav_location"             => "users#get_user_fav_location"           , via: [:get, :post]



    match "topics/create"                           => "topics#create"                          , via: [:get, :post]
    match "topics/search"                           => "topics#search"                          , via: [:get, :post]
    match "topics/favr_topics_by_user"              => "topics#favr_topics_by_user"             , via: [:get, :post]
    match "topics/favr_action"                      => "topics#favr_action"                     , via: [:get, :post]
    match "topics/honor_to_owner"                   => "topics#honor_to_owner"                  , via: [:get, :post]
    match "topics/user_rating"                      => "topics#user_rating"                     , via: [:get, :post]

    match "topics/topic_liked"                      => "topics#topic_liked"                     , via: [:get, :post]
    match "topics/topic_offensive"                  => "topics#topic_offensive"                 , via: [:get, :post]
    match "topics/topic_favourited"                 => "topics#topic_favourited"                , via: [:get, :post]
    match "topics/topics_by_ids"                    => "topics#topics_by_ids"                   , via: [:get, :post]
    match "topics/delete"                           => "topics#delete"                          , via: [:get, :post]
    match "topics/get_topic"                        => "topics#get_topic"                       , via: [:get, :post]
    match "topics/get_alltopic"                     => "topics#get_alltopic"                    , via: [:get, :post]

    match "topics/update_topic"                     => "topics#update_topic"                    , via: [:get, :post]
    match "topics/favtopic_create"                  => "topics#favtopic_create"                 , via: [:get, :post]

    match "posts/create"                            => "posts#create"                           , via: [:get, :post]
    match "posts/retrieve_post"                     => "posts#retrieve_post"                    , via: [:get, :post]
    match "posts/post_liked"                        => "posts#post_liked"                       , via: [:get, :post]
    match "posts/post_offensive"                    => "posts#post_offensive"                   , via: [:get, :post]
    match "posts/posts_by_ids"                      => "posts#posts_by_ids"                     , via: [:get, :post]
    match "posts/delete"                            => "posts#delete"                           , via: [:get, :post]

    match "userpushtokens/create"                   => "userpushtokens#create"                  , via: [:get, :post]

    match "places/create"                           => "places#create"                          , via: [:get, :post]
    match "places/retrieve_places"                  => "places#retrieve_places"                 , via: [:get, :post]
    match "places/select_venue"                     => "places#select_venue"                    , via: [:get, :post]
    match "places/user_recent_places"               => "places#user_recent_places"              , via: [:get, :post]
    match "places/information"                      => "places#information"                     , via: [:get, :post]
    match "places/top_venue_users"                  => "places#top_venue_users"                 , via: [:get, :post]
    match "places/currently_active"                 => "places#currently_active"                , via: [:get, :post]
    match "places/within_location"                  => "places#within_location"                 , via: [:get, :post]
    match "places/within_locality"                  => "places#within_locality"                 , via: [:get, :post]
    match "places/getlatlngbyname"                  => "places#getlatlngbyname"                 , via: [:get, :post]
    match "places/get_meal_suggestion"              => "places#get_meal_suggestion"          , via: [:get, :post]

    match "demo/test"                               => "demo#test"                              , via: [:get, :post]
    match "demo/test2"                              => "demo#test2"                             , via: [:get, :post]
    match "demo/test3"                              => "demo#test3"                             , via: [:get, :post]
    match "demo/test4"                              => "demo#test4"                             , via: [:get, :post]
    match "demo/sign_in"                            => "demo#sign_in"                           , via: [:get, :post]

    match "tags/delete"                             => "tags#delete"                            , via: [:get, :post]
    match "tags/within_location"                    => "tags#within_location"                   , via: [:get, :post]
    match "tags/retrieve_all_tags"                  => "tags#retrieve_all_tags"                 , via: [:get, :post]
    match "tags/retrieve_meal_tags"                 => "tags#retrieve_meal_tags"                , via: [:get, :post]

    match "topics/get_topic_by_image"               => "topics#topic_by_image"                  , via: [:get, :post]
  end

end
