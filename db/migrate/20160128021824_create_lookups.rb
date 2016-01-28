class CreateLookups < ActiveRecord::Migration
  def change
    create_table :lookups do |t|
      t.string :lookup_type
      t.string :name
      t.string :value

      t.timestamps null: false
    end
  end
end
