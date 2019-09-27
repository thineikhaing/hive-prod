class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def callback
    dispatcher.new(webhook, user).process
    render nothing: true, head: :ok
  end

  def webhook
    params['webhook']
  end

  def dispatcher
    BotMessageDispatcher
  end

  def from
    webhook[:message][:from]
  end

  def user
    @user ||= TelegramUser.find_by(telegram_id: from[:id]) || register_user
  end

  def register_user
    @user = TelegramUser.find_or_initialize_by(telegram_id: from[:id])
    @user.update_attributes!(first_name: from[:first_name], last_name: from[:last_name])
    @user

  end
end

class BotMessageDispatcher
  attr_reader :message, :user

  def initialize(message, user)
    @message = message
    @user = user
  end

  def process
    if user.get_next_bot_command
      unknown_command
      # bot_command = user.get_next_bot_command.safe_constantize.new(user, message)

      # if bot_command.should_start?
      #   bot_command.start
      # else
      #   unknown_command
      # end
    else
      start_command = BotCommand::Start.new(user, message)

      if start_command.should_start?
        start_command.start
      else
        unknown_command
      end
    end
  end

  private

  def unknown_command
    BotCommand::Undefined.new(user, message).start
  end
end

require "telegram/bot"

module BotCommand
  class Base
    attr_reader :user, :message, :api

    def initialize(user, message)
      @user = user
      @message = message
      token = Rails.application.secrets.bot_token
      @api = ::Telegram::Bot::Api.new(token)
    end

    def should_start?
      raise NotImplementedError
    end

    def start
      raise NotImplementedError
    end

    protected

    def send_message(text, options={})
      @api.call("sendMessage", chat_id: @user.telegram_id, text: text)
    end

    def text
      @message[:message][:text]
    end

    def from
      @message[:message][:from]
    end
  end

end

module BotCommand
  class Undefined < Base
    def start
      send_message('Unknown command. Type /start if you are a new user or you have finished the game, else type the appropriate command.')
    end
  end
end

module BotCommand
  class Start < Base
    def should_start?
      text =~ /\A\/start/
    end

    def start
      send_message('Hello! Here is a simple quest game! Type /born to start your interesting journey to the Rails rockstar position!')
      user.reset_next_bot_command
      user.set_next_bot_command('BotCommand::Born')
    end
  end
end
