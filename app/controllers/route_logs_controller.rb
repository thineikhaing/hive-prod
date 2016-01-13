class RouteLogsController < ApplicationController
  before_action :set_route_log, only: [:show, :edit, :update, :destroy]

  # GET /route_logs
  # GET /route_logs.json
  def index
    @route_logs = RouteLog.all
  end

  # GET /route_logs/1
  # GET /route_logs/1.json
  def show
  end

  # GET /route_logs/new
  def new
    @route_log = RouteLog.new
  end

  # GET /route_logs/1/edit
  def edit
  end

  # POST /route_logs
  # POST /route_logs.json
  def create
    @route_log = RouteLog.new(route_log_params)

    respond_to do |format|
      if @route_log.save
        format.html { redirect_to @route_log, notice: 'Route log was successfully created.' }
        format.json { render :show, status: :created, location: @route_log }
      else
        format.html { render :new }
        format.json { render json: @route_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /route_logs/1
  # PATCH/PUT /route_logs/1.json
  def update
    respond_to do |format|
      if @route_log.update(route_log_params)
        format.html { redirect_to @route_log, notice: 'Route log was successfully updated.' }
        format.json { render :show, status: :ok, location: @route_log }
      else
        format.html { render :edit }
        format.json { render json: @route_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /route_logs/1
  # DELETE /route_logs/1.json
  def destroy
    @route_log.destroy
    respond_to do |format|
      format.html { redirect_to route_logs_url, notice: 'Route log was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_route_log
      @route_log = RouteLog.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def route_log_params
      params.require(:route_log).permit(:user_id, :start_address, :end_address, :start_latitude, :start_longitude, :end_latitude, :end_longitude, :start_time, :end_time, :transport_type)
    end
end
