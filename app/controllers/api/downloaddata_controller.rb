class Api::DownloaddataController < ApplicationController
  def initial_retrieve
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      params[:radius].present? ? radius = params[:radius] : radius = nil

      if hiveApplication.present?
        render json: { topics: Place.nearest_topics_within(params[:latitude], params[:longitude], params[:radius]) }
      else
        render json: { status: false }
      end
    end
  end
end
