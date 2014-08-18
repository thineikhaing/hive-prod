class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.integer :tag_type, null: false
      t.string :keyword , null: false, default: ""

      t.timestamps
    end
  end
end
