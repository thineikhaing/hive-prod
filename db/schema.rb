# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180918101320) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "action_logs", force: :cascade do |t|
    t.string "action_type", null: false
    t.string "type_name", null: false
    t.integer "type_id", null: false
    t.integer "action_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_additional_fields", force: :cascade do |t|
    t.integer "app_id"
    t.string "table_name"
    t.string "additional_column_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "car_action_logs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "speed"
    t.integer "direction"
    t.float "latitude"
    t.float "longitude"
    t.string "activity"
    t.string "heartrate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "checkinplaces", force: :cascade do |t|
    t.integer "place_id", default: 0
    t.integer "user_id", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "locale_name"
    t.string "cca2"
    t.string "ccn3"
    t.string "cca3"
    t.string "tld"
    t.string "currency"
    t.integer "calling_code"
    t.string "capital"
    t.string "alt_spellings"
    t.float "relevance"
    t.string "region"
    t.string "subregion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "devices", force: :cascade do |t|
    t.string "push_token"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "devusers", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "username"
    t.string "email_verification_code", default: "", null: false
    t.string "default", default: "", null: false
    t.hstore "data"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hiveapplication_id"
    t.integer "role"
    t.index ["email"], name: "index_devusers_on_email", unique: true
    t.index ["hiveapplication_id"], name: "index_devusers_on_hiveapplication_id"
    t.index ["reset_password_token"], name: "index_devusers_on_reset_password_token", unique: true
  end

  create_table "favractions", force: :cascade do |t|
    t.bigint "topic_id"
    t.integer "doer_user_id"
    t.integer "status", default: 0
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_id"
    t.integer "honor_to_owner", default: 0
    t.integer "honor_to_doer", default: 0
    t.index ["topic_id"], name: "index_favractions_on_topic_id"
    t.index ["user_id"], name: "index_favractions_on_user_id"
  end

  create_table "historychanges", force: :cascade do |t|
    t.string "type_action", default: ""
    t.string "type_name", default: ""
    t.integer "type_id", default: 0
    t.integer "parent_id", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hive_applications", force: :cascade do |t|
    t.string "app_name"
    t.string "app_type", null: false
    t.string "api_key", null: false
    t.string "description", default: ""
    t.string "icon_url"
    t.string "theme_color", default: "#451734"
    t.integer "devuser_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "incident_histories", force: :cascade do |t|
    t.integer "host_id"
    t.integer "peer_id"
    t.hstore "host_data"
    t.hstore "peer_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitees", force: :cascade do |t|
    t.string "invitation_code"
    t.integer "topic_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lookups", force: :cascade do |t|
    t.string "lookup_type"
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "places", force: :cascade do |t|
    t.string "name"
    t.string "category", default: ""
    t.string "address", default: "", null: false
    t.string "locality", default: ""
    t.string "region", default: ""
    t.string "neighbourhood", default: ""
    t.string "country", default: ""
    t.string "postal_code", default: ""
    t.string "website_url", default: ""
    t.string "chain_name", default: ""
    t.string "contact_number", default: ""
    t.string "img_url"
    t.string "source", default: ""
    t.string "source_id", default: "0"
    t.integer "user_id"
    t.hstore "data"
    t.float "latitude", default: 0.0, null: false
    t.float "longitude", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name"
  end

  create_table "posts", force: :cascade do |t|
    t.string "content", null: false
    t.string "img_url"
    t.integer "width", default: 0
    t.integer "height", default: 0
    t.integer "post_type", default: 0, null: false
    t.hstore "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dislikes", default: 0
    t.integer "likes", default: 0
    t.integer "offensive", default: 0
    t.integer "place_id", default: 0
    t.bigint "user_id"
    t.bigint "topic_id"
    t.float "latitude"
    t.float "longitude"
    t.integer "special_type", default: 0
    t.index ["topic_id"], name: "index_posts_on_topic_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "privacy_policies", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "hiveapplication_id"
  end

  create_table "route_logs", force: :cascade do |t|
    t.integer "user_id"
    t.string "start_address"
    t.string "end_address"
    t.float "start_latitude"
    t.float "start_longitude"
    t.float "end_latitude"
    t.float "end_longitude"
    t.time "start_time"
    t.time "end_time"
    t.string "transport_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "sg_accident_histories", force: :cascade do |t|
    t.string "type"
    t.string "message"
    t.datetime "accident_datetime"
    t.float "latitude"
    t.float "longitude"
    t.text "summary"
    t.boolean "notify", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "place_id"
  end

  create_table "sg_bus_routes", force: :cascade do |t|
    t.string "service_no"
    t.string "operator"
    t.integer "direction"
    t.integer "stop_sequence"
    t.string "bus_stop_code"
    t.float "distance"
    t.string "wd_firstbus"
    t.string "wd_lastbus"
    t.string "sat_firstbus"
    t.string "sat_lastbus"
    t.string "sun_firstbus"
    t.string "sun_lastbus"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sg_bus_services", force: :cascade do |t|
    t.string "service_no"
    t.string "operator"
    t.integer "direction"
    t.string "category"
    t.string "origin_code"
    t.string "destination_code"
    t.string "am_peak_freq"
    t.string "am_offpeak_freq"
    t.string "pm_peak_freq"
    t.string "pm_offpeak_freq"
    t.string "loop_desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sg_bus_stops", id: :serial, force: :cascade do |t|
    t.string "bus_id"
    t.string "road_name"
    t.string "description"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sg_mrt_stations", force: :cascade do |t|
    t.string "type"
    t.string "code"
    t.string "name"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suggesteddates", force: :cascade do |t|
    t.integer "topic_id"
    t.integer "user_id"
    t.string "invitation_code"
    t.datetime "suggested_datetime"
    t.time "suggesttime"
    t.integer "vote", default: 0
    t.boolean "admin_confirm", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.integer "tag_type", null: false
    t.string "keyword", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "taxi_availabilities", force: :cascade do |t|
    t.float "latitude"
    t.float "longitude"
    t.datetime "date_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topic_invitees", force: :cascade do |t|
    t.integer "topic_id"
    t.string "invitee_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topic_with_tags", force: :cascade do |t|
    t.integer "topic_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topics", force: :cascade do |t|
    t.string "title", null: false
    t.string "image_url"
    t.integer "width", default: 0
    t.integer "height", default: 0
    t.integer "topic_type", default: 0, null: false
    t.integer "topic_sub_type", default: 0
    t.string "special_type", default: ""
    t.integer "place_id", default: 0
    t.float "value", default: 0.0
    t.string "unit", default: ""
    t.integer "dislikes", default: 0
    t.integer "likes", default: 0
    t.integer "offensive", default: 0
    t.float "notification_range", default: 1.0
    t.hstore "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hiveapplication_id"
    t.bigint "user_id"
    t.string "extra_info"
    t.datetime "valid_start_date"
    t.datetime "valid_end_date"
    t.integer "points"
    t.integer "free_points"
    t.integer "state"
    t.string "title_indexes"
    t.integer "checker"
    t.integer "given_time"
    t.integer "start_place_id", default: 0
    t.integer "end_place_id", default: 0
    t.index ["hiveapplication_id"], name: "index_topics_on_hiveapplication_id"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "trips", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "start_place_id"
    t.integer "end_place_id"
    t.string "transit_mode"
    t.datetime "depature_time"
    t.datetime "arrival_time"
    t.float "distance"
    t.float "fare"
    t.hstore "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "depart_latlng"
    t.string "arr_latlng"
    t.string "depature_name"
    t.string "arrival_name"
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "tweets", force: :cascade do |t|
    t.string "text"
    t.hstore "hashtags"
    t.datetime "posted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "creator"
  end

  create_table "user_accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "account_type", null: false
    t.string "linked_account_id", null: false
    t.integer "priority", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "hiveapplication_id"
  end

  create_table "user_fav_buses", force: :cascade do |t|
    t.integer "user_id"
    t.string "service"
    t.string "busid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_fav_locations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "place_id"
    t.string "place_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "img_url"
  end

  create_table "user_friend_lists", force: :cascade do |t|
    t.integer "user_id"
    t.integer "friend_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_hiveapps", force: :cascade do |t|
    t.integer "user_id"
    t.integer "hive_application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_push_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "push_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "endpoint_arn"
    t.boolean "notify", default: true
  end

  create_table "userpreviouslocations", force: :cascade do |t|
    t.float "latitude", default: 0.0
    t.float "longitude", default: 0.0
    t.integer "user_id", default: 0
    t.integer "radius", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "token_expiry_date"
    t.string "username", default: "", null: false
    t.string "device_id"
    t.string "authentication_token"
    t.string "avatar_url"
    t.integer "role"
    t.integer "points", default: 0
    t.integer "flareMode", default: 0
    t.integer "alert_count", default: 3
    t.integer "paid_alert_count", default: 0
    t.float "credits", default: 0.0
    t.float "last_known_latitude", default: 0.0
    t.float "last_known_longitude", default: 0.0
    t.datetime "check_in_time"
    t.integer "profanity_counter", default: 0
    t.datetime "offence_date"
    t.integer "positive_honor", default: 0
    t.integer "negative_honor", default: 0
    t.integer "honored_times", default: 0
    t.hstore "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "socal_id"
    t.integer "daily_points", default: 10
    t.hstore "app_data"
    t.string "email_verification_code"
    t.boolean "verified", default: false
    t.boolean "socal_register", default: false
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.integer "vote"
    t.datetime "selected_datetime"
    t.integer "user_id"
    t.integer "topic_id"
    t.integer "suggesteddate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
