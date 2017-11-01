class CreateFavractions < ActiveRecord::Migration[5.1]
  def up
    create_table :favractions do |t|
      t.integer :topic_id
      t.integer :doer_user_id
      t.integer :status,    :default => 0

      t.references :topic
      t.references :user
      t.timestamps
    end
  end

  def down
    drop_table :favractions
  end
end
