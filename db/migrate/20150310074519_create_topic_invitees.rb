class CreateTopicInvitees < ActiveRecord::Migration
  def change
    create_table :topic_invitees do |t|
      t.integer :topic_id
      t.string :invitee_email

      t.timestamps
    end
  end
end
