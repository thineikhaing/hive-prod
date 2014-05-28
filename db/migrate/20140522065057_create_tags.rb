class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.integer :tag_type
      t.string :keyword

      t.timestamps
    end
  end
end
