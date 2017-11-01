class ChangeColumnsAdminConfirmToSuggesteddates < ActiveRecord::Migration[5.1]
  def up
    change_column :suggesteddates, :admin_confirm, :boolean, default: false
  end

  def down
    change_column :suggesteddates, :admin_confirm, :boolean, default: ''
  end
end
