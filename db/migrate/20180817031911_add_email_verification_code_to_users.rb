class AddEmailVerificationCodeToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :email_verification_code, :string
    add_column :users, :verified, :boolean, default: false
  end
end
