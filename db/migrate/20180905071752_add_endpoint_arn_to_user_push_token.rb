class AddEndpointArnToUserPushToken < ActiveRecord::Migration[5.1]
  def change
    add_column :user_push_tokens, :endpoint_arn, :string
  end
end
