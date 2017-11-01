class AddColumnsSpecialTypeToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :special_type, :integer, :default => 0
  end
end
