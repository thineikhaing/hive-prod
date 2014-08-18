class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :content, null: false
      t.string :img_url
      t.integer :width, default: 0
      t.integer :height, default: 0
      t.integer :post_type,  null: false, default: 0
      t.hstore :data
      t.timestamps
      t.integer :dislikes,  :default => 0
      t.integer :likes,     :default => 0
      t.integer :offensive, :default => 0

      t.integer :place_id,  default: 0
      t.references :user
      t.references :topic
    end
  end
end
