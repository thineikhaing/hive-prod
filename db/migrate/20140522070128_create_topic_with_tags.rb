class CreateTopicWithTags < ActiveRecord::Migration
  def change
    create_table :topic_with_tags do |t|
      t.integer :topic_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
