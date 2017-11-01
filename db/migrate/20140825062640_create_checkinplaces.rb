class CreateCheckinplaces < ActiveRecord::Migration[5.1]

  def up
    create_table :checkinplaces do |t|
      t.integer :place_id,  :default => 0
      t.integer :user_id,   :default => 0

      t.timestamps
    end
  end

  def down
    drop_table :checkinplaces
  end

end
