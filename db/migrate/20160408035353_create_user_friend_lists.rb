class CreateUserFriendLists < ActiveRecord::Migration[5.1]
  def change
    create_table :user_friend_lists do |t|
      t.integer :user_id
      t.integer :friend_id

      t.timestamps null: false
    end
  end
end
