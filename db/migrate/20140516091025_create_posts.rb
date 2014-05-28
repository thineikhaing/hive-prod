class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :content
      t.integer :post_type
      t.hstore :data
      t.timestamps

      t.references :user
      t.references :topic
    end
  end
end
