class AddRoleToDevuser < ActiveRecord::Migration[5.1]
  def change
    add_column :devusers, :role, :integer
  end
end
