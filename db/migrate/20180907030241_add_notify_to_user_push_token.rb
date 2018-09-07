class AddNotifyToUserPushToken < ActiveRecord::Migration[5.1]
  def change
    add_column :user_push_tokens, :notify, :boolean, default: true
  end
end
