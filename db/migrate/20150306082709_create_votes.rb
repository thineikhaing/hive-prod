class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer :vote
      t.datetime :selected_datetime
      t.integer :user_id
      t.integer :topic_id
      t.integer :suggesteddate_id

      t.timestamps
    end
  end
end
