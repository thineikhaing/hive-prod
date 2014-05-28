class CreateSocialAccounts < ActiveRecord::Migration
  def change
    create_table :social_accounts do |t|
      t.integer :account_type
      t.integer :account_id

      t.references :user
      t.timestamps
    end
  end
end
