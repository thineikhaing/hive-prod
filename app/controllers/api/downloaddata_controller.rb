class Api::DownloaddataController < ApplicationController


  def initial_retrieve
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      params[:radius].present? ? radius = params[:radius] : radius = nil

      topics = Place.nearest_topics_within(params[:latitude], params[:longitude], radius)

      if hiveApplication.present?
        render json: { topics: topics}
      else
        render json: { status: false }
      end
    end
  end

  def retrieve_hiveapplications
    render json: {apps: HiveApplication.all.to_json(:test => "true") }
  end
end
