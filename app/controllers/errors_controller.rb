class ErrorsController < ApplicationController
  layout :special_layout
  def error_404
      @requested_path = request.path
      respond_to do |format|
        format.html
        format.json { render json: {routing_error: @requested_path} }
      end
    end

    def special_layout
      "special_layout"
    end

end
