class ChangeColumnNullToPushToken < ActiveRecord::Migration[5.1]
  def change
    change_column_null :user_push_tokens, :push_token, true
  end
end
