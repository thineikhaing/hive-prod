class CreateHistorychanges < ActiveRecord::Migration[5.1]
  def up
    create_table :historychanges do |t|
      t.string :type_action,  :default => ""
      t.string :type_name,    :default => ""
      t.integer :type_id,     :default => 0
      t.integer :parent_id,   :default => 0

      t.timestamps
    end
  end

  def down
    drop_table :historychanges
  end
end
