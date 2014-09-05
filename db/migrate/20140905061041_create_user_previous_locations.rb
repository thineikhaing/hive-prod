class CreateUserPreviousLocations < ActiveRecord::Migration
  def change

    create_table :userpreviouslocations do |t|
      t.float :latitude,    :default => 0
      t.float :longitude,   :default => 0
      t.integer :user_id,   :default => 0
      t.integer :radius,    :default => 0

      t.timestamps
    end

  end
end
