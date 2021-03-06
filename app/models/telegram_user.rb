class TelegramUser < ApplicationRecord
  validates_uniqueness_of :telegram_id
  def set_next_bot_command(command)
    self.bot_command_data["command"] = command
    save
  end

  def get_next_bot_command
    bot_command_data["command"]
  end

  def reset_next_bot_command
    self.bot_command_data = {}
    save
  end
end
