class AddShortNameToPlace < ActiveRecord::Migration[5.0]
  def change
    add_column :places, :short_name, :string
  end
end
