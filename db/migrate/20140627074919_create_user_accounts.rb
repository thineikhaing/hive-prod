class CreateUserAccounts < ActiveRecord::Migration
  def change
    create_table :user_accounts do |t|
      t.integer :user_id, null: false
      t.string  :account_type, null: false
      t.string  :linked_account_id, null: false
      t.integer :priority, default: 0
      t.timestamps
    end
  end
end
