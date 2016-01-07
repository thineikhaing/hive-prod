class AddRoleToDevuser < ActiveRecord::Migration
  def change
    add_column :devusers, :role, :integer
  end
end
