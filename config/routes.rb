Rails.application.routes.draw do

  root to: 'hiveapplication#login_page'
  post "dev_sign_in"              =>  'home#dev_sign_in'        , via: [:get, :post]
  # match "application_portal"      => "home#application_portal"  , as: "home/application_portal", via: [:get, :post]
  match "devapp_list"             =>  'home#devapp_list'        , via: [:get, :post]
  match "get_topic_by_map"        =>  'home#get_topic_by_map'   , via: [:get, :post]
  match "home/edit_application"   =>  'home#edit_application'   , via: [:get, :post]
  post "create_train_fault_alert" => 'home#create_train_fault_alert', via: [:get, :post]

  get 'carmic' => 'carmic#index', as: 'carmic'
  get 'create_train_fault_alert' => 'hiveapplication#create_train_fault_alert'
  get   'user_accounts/:id' => 'hiveapplication#user_accounts', :as => :user_accounts
  devise_for :users
  devise_for :devusers

  resources :sg_accident_histories
  resources :privacy_policies
  resources :user_fav_locations
  resources :lookups
  resources :route_logs
  resources :hiveapplication
  resources :car_action_logs
  resources :places


  # match "create_train_fault_alert"      => 'hiveapplication#create_train_fault_alert'          , via: [:get, :post]
  post  "sign_in"                  => 'hiveapplication#sign_in'          , as: "hiveapplication/sign_in"
  get   "verify"                   => 'hiveapplication#verify'           , as: 'hiveapplication/verify'
  match "login_page"               => 'hiveapplication#login_page'       , as: "hiveapplication/login_page"   , via: [:get, :post]

  match "/index"    => 'hiveapplication#index'         , via: [:get, :post]

  match "dev_portal"               => 'hiveapplication#dev_portal'       , as: "hiveapplication/dev_portal"   , via: [:get, :post]
  match "application_list"         => 'hiveapplication#dev_portal'       , as: "hiveapplication/application_list", via: [:get, :post]

  match "sign_up"                  => 'hiveapplication#sign_up'          , as: "hiveapplication/sign_up"      , via: [:get, :post]

  match "regenerate_api_key"       => 'hiveapplication#regenerate_api_key' , as: "hiveapplication/regenerate_api_key"  , via: [:get, :post]
  match "delete_application"       => 'hiveapplication#delete_application' , as: "hiveapplication/delete_application" , via: [:get, :post]
  match "edit_application"         => 'hiveapplication#edit_application'  , as: "hiveapplication/edit_application"       , via: [:get, :post]
  match "add_application"          => 'hiveapplication#add_application' , as: "hiveapplication/add_application"           , via: [:get, :post]
  match "verify_signup"            => 'hiveapplication#verify_signup'  , as: "hiveapplication/verify_signup" , via: [:get, :post]
  match "forget_password"          => 'hiveapplication#forget_password' , as: "hiveapplication/forget_password"           , via: [:get, :post]
  match "reset_password"           => 'hiveapplication#reset_password'    , as: "hiveapplication/reset_password"          , via: [:get, :post]
  match "update_password"          => 'hiveapplication#update_password'   , as: "hiveapplication/update_password"         , via: [:get, :post]
  match "edit_column"              => 'hiveapplication#edit_column'          , as:"hiveapplication/edit_column"              , via: [:get, :post]
  match "delete_additional_column" => 'hiveapplication#delete_additional_column', as:"hiveapplication/delete_additional_column" , via: [:get, :post]
  match "update_additional_column" => 'hiveapplication#update_additional_column', as:"hiveapplication/update_additional_column" , via: [:get, :post]
  match "edit_additional_column"   => "hiveapplication#edit_additional_column" , as:"hiveapplication/edit_additional_column" , via: [:get, :post]
  match "create_additional_field"  => "hiveapplication#create_additional_field" , as:"hiveapplication/create_additional_field" , via: [:get, :post]
  match "clear_columns_changes"    => "hiveapplication#clear_columns_changes" , as:"hiveapplication/clear_columns_changes" , via: [:get, :post]
  match "save_columns_changes"     => "hiveapplication#save_columns_changes" , as:"hiveapplication/save_columns_changes" , via: [:get, :post]
  match "edit_topic_post"          => "hiveapplication#edit_topic_post" , as:"hiveapplication/edit_topic_post" , via: [:get, :post]
  match "delete_topic"             => "hiveapplication#delete_topic" , as:"hiveapplication/delete_topic" , via: [:get, :post]
  match "delete_post"              => "hiveapplication#delete_post" , as:"hiveapplication/delete_post" , via: [:get, :post]
  match "edit_topic"               => "hiveapplication#edit_topic" , as:"hiveapplication/edit_topic" , via: [:get, :post]
  match "edit_post"                => "hiveapplication#edit_post" , as:"hiveapplication/edit_post" , via: [:get, :post]
  match "users"                    => "hiveapplication#users"      , as:"hiveapplication/users" , via: [:get, :post]
  match "carmic/create_post"      => 'carmic#create_post'              , via: [:get,:post]
  match "carmic/singup"           => 'carmic#singup'                   , via: [:get,:post]
  match "carmic/login"            => 'carmic#login'                    , via: [:get,:post]
  match "carmic/camic_reset_pwd"  => "carmic#camic_reset_pwd"          , via: [:get,:post]
  match "carmic/create_post"      => 'carmic#create_post'              , via: [:get,:post]
  get "carmic/logout"             => 'carmic#logout'


  namespace :api do

    match "hivev2/get_topic_by_latlon"              => "hivev2#get_topic_by_latlon"            , via: [:get, :post]
    match "hivev2/place_for_map_view"               => "hivev2#place_for_map_view"             , via: [:get, :post]
    match "hivev2/get_posts_by_topicid"             => "hivev2#get_posts_by_topicid"           , via: [:get, :post]

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

    match "users/get_user"             => "users#get_user"            , via: [:get, :post]
    match "users/create_anonymous_user"             => "users#create_anonymous_user"            , via: [:get, :post]
    match "users/sign_up"                           => "users#sign_up"                          , via: [:get, :post]
    match "users/sign_in"                           => "users#sign_in"                          , via: [:get, :post]
    match "users/juice_sign_in"                     => "users#juice_sign_in"                    , via: [:get, :post]
    match "users/facebook_login"                    => "users#facebook_login"                   , via: [:get, :post]
    match "users/forget_password"                   => "users#forget_password"                  , via: [:get, :post]
    match "users/update_password"                   => "users#update_password"                  , via: [:get, :post]

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
    match "users/get_user_fav_location"             => "users#get_user_fav_location"            , via: [:get, :post]
    match "users/delete_user_fav_location"          => "users#delete_user_fav_location"         , via: [:get, :post]
    match "users/update_user_fav_location"          => "users#update_user_fav_location"         , via: [:get, :post]


    match "users/save_user_friend_list"             => "users#save_user_friend_list"            , via: [:get, :post]
    match "users/delete_user_friend_list"           => "users#delete_user_friend_list"          , via: [:get, :post]
    match "users/get_user_friend_list"              => "users#get_user_friend_list"             , via: [:get, :post]
    match "users/check_user_device_id"              => "users#check_user_device_id"             , via: [:get, :post]

    match "topics/create"                           => "topics#create"                          , via: [:get, :post]
    match "topics/search"                           => "topics#search"                          , via: [:get, :post]
    match "topics/favr_topics_by_user"              => "topics#favr_topics_by_user"             , via: [:get, :post]
    match "topics/favr_action"                      => "topics#favr_action"                     , via: [:get, :post]
    match "topics/honor_to_owner"                   => "topics#honor_to_owner"                  , via: [:get, :post]
    match "topics/user_rating"                      => "topics#user_rating"                     , via: [:get, :post]
    match "topics/topics_within_two_points"         => "topics#topics_within_two_points"        , via: [:get, :post]
    match "topics/topics_by_user"                   => "topics#topics_by_user"                  , via: [:get, :post]
    match "topics/check_user_last_topic"            => "topics#check_user_last_topic"           , via: [:get, :post]
    match "topics/check_transit_topic"              => "topics#check_transit_topic"           , via: [:get, :post]

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
    match "places/get_meal_suggestion"              => "places#get_meal_suggestion"             , via: [:get, :post]
    match "places/search_place_by_keyword"          => "places#search_place_by_keyword"         , via: [:get, :post]

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

    match "roundtrip/get_route_by_travelMode"       => "roundtrip#get_route_by_travelMode"      , via: [:get, :post]
    match "roundtrip/driving_route_mode"            => "roundtrip#driving_route_mode"           , via: [:get, :post]
    match "roundtrip/bicycling_route_mode"          => "roundtrip#bicycling_route_mode"         , via: [:get, :post]
    match "roundtrip/walking_route_mode"            => "roundtrip#walking_route_mode"           , via: [:get, :post]
    match "roundtrip/broadcast_trainfault"          => "roundtrip#broadcast_trainfault"         , via: [:get, :post]
    match "roundtrip/get_nearby_taxi"               => "roundtrip#get_nearby_taxi"              , via: [:get, :post]
    match "roundtrip/broadcast_roundtrip_users"     => "roundtrip#broadcast_roundtrip_users"    , via: [:get, :post]
    match "roundtrip/get_rt_privacy_policy"         => "roundtrip#get_rt_privacy_policy"    , via: [:get, :post]
    match "roundtrip/get_bus_arrival_time"          => "roundtrip#get_bus_arrival_time"    , via: [:get, :post]
    match "roundtrip/upload_rt_placeImage"          => "roundtrip#upload_rt_placeImage"    , via: [:get, :post]
    match "roundtrip/save_trip"                     => "roundtrip#save_trip"    , via: [:get, :post]
    match "roundtrip/get_trip"                      => "roundtrip#get_trip"    , via: [:get, :post]
    match "roundtrip/delete_trip"                   => "roundtrip#delete_trip"    , via: [:get, :post]
    match "roundtrip/get_smrt_tweets"               => "roundtrip#get_smrt_tweets"    , via: [:get, :post]

    match "roundtrip/get_user_fav_buses"            => "roundtrip#get_user_fav_buses"    , via: [:get, :post]
    match "roundtrip/save_user_fav_buses"           => "roundtrip#save_user_fav_buses"    , via: [:get, :post]
    match "roundtrip/transit_annoucement_by_admin"  => "roundtrip#transit_annoucement_by_admin"    , via: [:get, :post]
    match "roundtrip/demo_train_service_alert"      => "roundtrip#demo_train_service_alert"    , via: [:get, :post]
    match "roundtrip/send_alight_noti"              => "roundtrip#send_alight_noti"    , via: [:get, :post]
    match 'roundtrip/locations'   => "roundtrip#locations"    , via: [:get, :post]
  end

end
