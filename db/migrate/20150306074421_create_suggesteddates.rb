class CreateSuggesteddates < ActiveRecord::Migration
  def change
    create_table :suggesteddates do |t|
      t.integer :topic_id
      t.integer :user_id
      t.string :invitation_code
      t.datetime :suggested_datetime
      t.time :suggesttime
      t.integer :vote
      t.boolean :admin_confirm

      t.timestamps
    end
  end
end
