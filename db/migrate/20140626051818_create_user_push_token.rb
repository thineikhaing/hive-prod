class CreateUserPushToken < ActiveRecord::Migration
  create_table :user_push_tokens do |t|
    t.integer :user_id
    t.string  :push_token

    t.timestamps
  end
end
