class CreateTweets < ActiveRecord::Migration[5.1]
  def change
    create_table :tweets do |t|
      t.string :text
      t.hstore :hashtags
      t.datetime :posted_at

      t.timestamps
    end
  end
end
