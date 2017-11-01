class CreateTopicWithTags < ActiveRecord::Migration[5.1]
  def change
    create_table :topic_with_tags do |t|
      t.integer :topic_id, null: false
      t.integer :tag_id, null: false

      t.timestamps
    end
  end
end
