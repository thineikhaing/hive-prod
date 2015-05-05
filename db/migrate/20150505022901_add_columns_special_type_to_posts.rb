class AddColumnsSpecialTypeToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :special_type, :integer, :default => 0
  end
end
