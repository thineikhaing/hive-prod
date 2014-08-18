class CreateUserPushToken < ActiveRecord::Migration
  create_table :user_push_tokens do |t|
    t.integer :user_id, null: false
    t.string  :push_token, null: false

    t.timestamps
  end
end
