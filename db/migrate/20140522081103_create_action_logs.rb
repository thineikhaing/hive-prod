class CreateActionLogs < ActiveRecord::Migration
  def change
    create_table :action_logs do |t|
      t.string :action_type
      t.string :type_name
      t.integer :type_id
      t.integer :action_user_id

      t.timestamps
    end
  end
end
