class CreateTopics < ActiveRecord::Migration
  def change
    create_table :topics do |t|
      t.string :title
      t.string :image_url
      t.integer :topic_sub_type
      t.integer :place_id
      t.hstore :data
      t.timestamps

      t.references :hiveapplication
      t.references :user
    end
  end
end
