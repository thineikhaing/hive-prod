class CreateActionLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :action_logs do |t|
      t.string :action_type, null: false
      t.string :type_name, null: false
      t.integer :type_id, null: false
      t.integer :action_user_id, null: false

      t.timestamps
    end
  end
end
