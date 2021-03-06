class CreateTopics < ActiveRecord::Migration[5.1]
  def change
    create_table :topics do |t|
      t.string :title, null: false
      t.string :image_url
      t.integer :width, default: 0
      t.integer :height, default: 0
      t.integer :topic_type, null: false, default: 0
      t.integer :topic_sub_type , default: 0
      t.string :special_type, :default => ""
      t.integer :place_id, :default => 0
      t.float :value, :default => 0
      t.string :unit, :default => ""
      t.integer :dislikes,    :default => 0
      t.integer :likes,       :default => 0
      t.integer :offensive,   :default => 0
      t.float :notification_range,        :default => 1.0

      t.hstore :data
      t.timestamps


      t.references :hiveapplication
      t.references :user
    end
  end
end
