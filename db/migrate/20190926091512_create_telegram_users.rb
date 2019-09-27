class CreateTelegramUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :telegram_users do |t|
      t.string :telegram_id
      t.string :first_name
      t.string :last_name
      t.jsonb :bot_command_data, default: {}
      t.timestamps
    end
  end
end
