class CreateUserAccounts < ActiveRecord::Migration
  def change
    create_table :user_accounts do |t|
      t.integer :user_id
      t.string  :account_type
      t.string  :linked_account_id
      t.integer :priority

      t.timestamps
    end
  end
end
