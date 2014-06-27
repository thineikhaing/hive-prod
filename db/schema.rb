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

ActiveRecord::Schema.define(version: 20140627074919) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "action_logs", force: true do |t|
    t.string   "action_type"
    t.string   "type_name"
    t.integer  "type_id"
    t.integer  "action_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "app_additional_fields", force: true do |t|
    t.integer  "app_id"
    t.string   "table_name"
    t.string   "additional_column_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "devices", force: true do |t|
    t.string   "push_token"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "devusers", force: true do |t|
    t.string   "email",                   default: "",    null: false
    t.string   "encrypted_password",      default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "username"
    t.string   "email_verification_code"
    t.hstore   "data"
    t.boolean  "verified",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hiveapplication_id"
  end

  add_index "devusers", ["email"], name: "index_devusers_on_email", unique: true, using: :btree
  add_index "devusers", ["reset_password_token"], name: "index_devusers_on_reset_password_token", unique: true, using: :btree

  create_table "facades", force: true do |t|
    t.string   "social_priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "hive_applications", force: true do |t|
    t.string   "app_name"
    t.string   "app_type"
    t.string   "api_key"
    t.string   "description"
    t.string   "icon_url"
    t.integer  "devuser_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "places", force: true do |t|
    t.string   "name"
    t.string   "category"
    t.string   "address"
    t.string   "locality"
    t.string   "region"
    t.string   "neighbourhood"
    t.string   "country"
    t.string   "postal_code"
    t.string   "website_url"
    t.string   "chain_name"
    t.string   "contact_number"
    t.string   "img_url"
    t.string   "source"
    t.integer  "source_id"
    t.integer  "user_id"
    t.hstore   "data"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", force: true do |t|
    t.string   "content"
    t.integer  "post_type"
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "topic_id"
  end

  create_table "social_accounts", force: true do |t|
    t.integer  "account_type"
    t.integer  "account_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", force: true do |t|
    t.integer  "tag_type"
    t.string   "keyword"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_with_tags", force: true do |t|
    t.integer  "topic_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topics", force: true do |t|
    t.string   "title"
    t.string   "image_url"
    t.integer  "topic_sub_type"
    t.integer  "place_id"
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hiveapplication_id"
    t.integer  "user_id"
  end

  create_table "user_accounts", force: true do |t|
    t.integer  "user_id"
    t.string   "account_type"
    t.string   "linked_account_id"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_push_tokens", force: true do |t|
    t.integer  "user_id"
    t.string   "push_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "token_expiry_date"
    t.string   "username"
    t.string   "device_id"
    t.string   "authentication_token"
    t.string   "avatar_url"
    t.integer  "role"
    t.integer  "quid"
    t.integer  "honor_rating"
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
