class AddSocalRegisterToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :socal_register, :boolean, default: false
  end
end
