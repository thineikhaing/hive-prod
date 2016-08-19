class ChangeSourceIdTypeInPlaces < ActiveRecord::Migration[5.0]
  def up
    change_column :places, :source_id, :string
  end

  def down
    change_column :places,:source_id, :string
  end
end
