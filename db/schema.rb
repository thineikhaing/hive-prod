# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160608053352) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "action_logs", force: :cascade do |t|
    t.string   "action_type",    limit: 255, null: false
    t.string   "type_name",      limit: 255, null: false
    t.integer  "type_id",                    null: false
    t.integer  "action_user_id",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "app_additional_fields", force: :cascade do |t|
    t.integer  "app_id"
    t.string   "table_name",             limit: 255
    t.string   "additional_column_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "car_action_logs", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "speed"
    t.integer  "direction"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "activity",   limit: 255
    t.string   "heartrate",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "checkinplaces", force: :cascade do |t|
    t.integer  "place_id",   default: 0
    t.integer  "user_id",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "countries", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "locale_name",   limit: 255
    t.string   "cca2",          limit: 255
    t.string   "ccn3",          limit: 255
    t.string   "cca3",          limit: 255
    t.string   "tld",           limit: 255
    t.string   "currency",      limit: 255
    t.integer  "calling_code"
    t.string   "capital",       limit: 255
    t.string   "alt_spellings", limit: 255
    t.float    "relevance"
    t.string   "region",        limit: 255
    t.string   "subregion",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",               default: 0, null: false
    t.integer  "attempts",               default: 0, null: false
    t.text     "handler",                            null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "devices", force: :cascade do |t|
    t.string   "push_token", limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "devusers", force: :cascade do |t|
    t.string   "email",                   limit: 255, default: "",    null: false
    t.string   "encrypted_password",      limit: 255, default: "",    null: false
    t.string   "reset_password_token",    limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",      limit: 255
    t.string   "last_sign_in_ip",         limit: 255
    t.string   "username",                limit: 255
    t.string   "email_verification_code", limit: 255, default: "",    null: false
    t.string   "default",                 limit: 255, default: "",    null: false
    t.hstore   "data"
    t.boolean  "verified",                            default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hiveapplication_id"
    t.integer  "role"
  end

  add_index "devusers", ["email"], name: "index_devusers_on_email", unique: true, using: :btree
  add_index "devusers", ["reset_password_token"], name: "index_devusers_on_reset_password_token", unique: true, using: :btree

  create_table "favractions", force: :cascade do |t|
    t.integer  "topic_id"
    t.integer  "doer_user_id"
    t.integer  "status",         default: 0
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "post_id"
    t.integer  "honor_to_owner", default: 0
    t.integer  "honor_to_doer",  default: 0
  end

  create_table "historychanges", force: :cascade do |t|
    t.string   "type_action", limit: 255, default: ""
    t.string   "type_name",   limit: 255, default: ""
    t.integer  "type_id",                 default: 0
    t.integer  "parent_id",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hive_applications", force: :cascade do |t|
    t.string   "app_name",    limit: 255
    t.string   "app_type",    limit: 255,                     null: false
    t.string   "api_key",     limit: 255,                     null: false
    t.string   "description", limit: 255, default: ""
    t.string   "icon_url",    limit: 255
    t.string   "theme_color", limit: 255, default: "#451734"
    t.integer  "devuser_id",                                  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "incident_histories", force: :cascade do |t|
    t.integer  "host_id"
    t.integer  "peer_id"
    t.hstore   "host_data"
    t.hstore   "peer_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitees", force: :cascade do |t|
    t.string   "invitation_code", limit: 255
    t.integer  "topic_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookups", force: :cascade do |t|
    t.string   "lookup_type"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "places", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "category",       limit: 255, default: ""
    t.string   "address",        limit: 255, default: "",  null: false
    t.string   "locality",       limit: 255, default: ""
    t.string   "region",         limit: 255, default: ""
    t.string   "neighbourhood",  limit: 255, default: ""
    t.string   "country",        limit: 255, default: ""
    t.string   "postal_code",    limit: 255, default: ""
    t.string   "website_url",    limit: 255, default: ""
    t.string   "chain_name",     limit: 255, default: ""
    t.string   "contact_number", limit: 255, default: ""
    t.string   "img_url",        limit: 255
    t.string   "source",         limit: 255, default: ""
    t.integer  "source_id",                  default: 0
    t.integer  "user_id"
    t.hstore   "data"
    t.float    "latitude",                   default: 0.0, null: false
    t.float    "longitude",                  default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", force: :cascade do |t|
    t.string   "content",      limit: 255,             null: false
    t.string   "img_url",      limit: 255
    t.integer  "width",                    default: 0
    t.integer  "height",                   default: 0
    t.integer  "post_type",                default: 0, null: false
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dislikes",                 default: 0
    t.integer  "likes",                    default: 0
    t.integer  "offensive",                default: 0
    t.integer  "place_id",                 default: 0
    t.integer  "user_id"
    t.integer  "topic_id"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "special_type",             default: 0
  end

  create_table "privacy_policies", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "route_logs", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "start_address"
    t.string   "end_address"
    t.float    "start_latitude"
    t.float    "start_longitude"
    t.float    "end_latitude"
    t.float    "end_longitude"
    t.time     "start_time"
    t.time     "end_time"
    t.string   "transport_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "routes_logs", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "start_address"
    t.string   "end_address"
    t.float    "start_latitude"
    t.float    "start_longitude"
    t.float    "end_latitude"
    t.float    "end_longitude"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "transport_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "sg_accident_histories", force: :cascade do |t|
    t.string   "type"
    t.string   "message"
    t.datetime "accident_datetime"
    t.float    "latitude"
    t.float    "longitude"
    t.text     "summary"
    t.boolean  "notify",            default: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "suggesteddates", force: :cascade do |t|
    t.integer  "topic_id"
    t.integer  "user_id"
    t.string   "invitation_code",    limit: 255
    t.datetime "suggested_datetime"
    t.time     "suggesttime"
    t.integer  "vote",                           default: 0
    t.boolean  "admin_confirm",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", force: :cascade do |t|
    t.integer  "tag_type",                            null: false
    t.string   "keyword",    limit: 255, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_invitees", force: :cascade do |t|
    t.integer  "topic_id"
    t.string   "invitee_email", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_with_tags", force: :cascade do |t|
    t.integer  "topic_id",   null: false
    t.integer  "tag_id",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topics", force: :cascade do |t|
    t.string   "title",              limit: 255,               null: false
    t.string   "image_url",          limit: 255
    t.integer  "width",                          default: 0
    t.integer  "height",                         default: 0
    t.integer  "topic_type",                     default: 0,   null: false
    t.integer  "topic_sub_type",                 default: 0
    t.string   "special_type",       limit: 255, default: ""
    t.integer  "place_id",                       default: 0
    t.float    "value",                          default: 0.0
    t.string   "unit",               limit: 255, default: ""
    t.integer  "dislikes",                       default: 0
    t.integer  "likes",                          default: 0
    t.integer  "offensive",                      default: 0
    t.float    "notification_range",             default: 1.0
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hiveapplication_id"
    t.integer  "user_id"
    t.string   "extra_info",         limit: 255
    t.datetime "valid_start_date"
    t.datetime "valid_end_date"
    t.integer  "points"
    t.integer  "free_points"
    t.integer  "state"
    t.string   "title_indexes",      limit: 255
    t.integer  "checker"
    t.integer  "given_time"
    t.integer  "start_place_id",                 default: 0
    t.integer  "end_place_id",                   default: 0
  end

  create_table "user_accounts", force: :cascade do |t|
    t.integer  "user_id",                                    null: false
    t.string   "account_type",       limit: 255,             null: false
    t.string   "linked_account_id",  limit: 255,             null: false
    t.integer  "priority",                       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hiveapplication_id"
  end

  create_table "user_fav_locations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "place_id"
    t.string   "place_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_friend_lists", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_push_tokens", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.string   "push_token", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "userpreviouslocations", force: :cascade do |t|
    t.float    "latitude",   default: 0.0
    t.float    "longitude",  default: 0.0
    t.integer  "user_id",    default: 0
    t.integer  "radius",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",  null: false
    t.string   "encrypted_password",     limit: 255, default: "",  null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,   null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "token_expiry_date"
    t.string   "username",               limit: 255, default: "",  null: false
    t.string   "device_id",              limit: 255
    t.string   "authentication_token",   limit: 255
    t.string   "avatar_url",             limit: 255
    t.integer  "role"
    t.integer  "points",                             default: 0
    t.integer  "flareMode",                          default: 0
    t.integer  "alert_count",                        default: 3
    t.integer  "paid_alert_count",                   default: 0
    t.float    "credits",                            default: 0.0
    t.float    "last_known_latitude",                default: 0.0
    t.float    "last_known_longitude",               default: 0.0
    t.datetime "check_in_time"
    t.integer  "profanity_counter",                  default: 0
    t.datetime "offence_date"
    t.integer  "positive_honor",                     default: 0
    t.integer  "negative_honor",                     default: 0
    t.integer  "honored_times",                      default: 0
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "socal_id"
    t.integer  "daily_points",                       default: 10
    t.hstore   "app_data"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "vote"
    t.datetime "selected_datetime"
    t.integer  "user_id"
    t.integer  "topic_id"
    t.integer  "suggesteddate_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
