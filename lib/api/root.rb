# lib/api/root.rb
module API
  class Root < Grape::API
    prefix    'api'
    format    :json

    rescue_from :all, :backtrace => true
    error_formatter :json, API::ErrorFormatter

    before do
      error!("401 Unauthorized", 401) unless authenticated
    end

    helpers do
      def warden
        env['warden']
      end

      def authenticated
        p "help"
        return true if warden.authenticated?
        params[:auth_token] && @user = User.find_by_authentication_token(params[:auth_token])
      end

      def my_current_user
        warden.user || @user
      end
    end

    mount API::V1::Root
    mount API::V2::Root
  end
end
