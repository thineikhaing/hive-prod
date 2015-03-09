class CreateInvitees < ActiveRecord::Migration
  def change
    create_table :invitees do |t|
      t.string :invitation_code
      t.integer :topic_id
      t.integer :user_id

      t.timestamps
    end
  end
end
