class ChangeColumnToSuggesteddates < ActiveRecord::Migration
  def up
    change_column :suggesteddates, :vote, :integer, default: 0
  end

  def down
    change_column :suggesteddates, :vote, :integer, default: nil
  end
end
