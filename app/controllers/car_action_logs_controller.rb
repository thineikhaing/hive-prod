class CarActionLogsController < ApplicationController
  before_action :set_car_action_log, only: [:show, :edit, :update, :destroy]

  # GET /car_action_logs
  # GET /car_action_logs.json
  def index
    @car_action_logs = CarActionLog.order("created_at desc").page params[:page]

  end

  # GET /car_action_logs/1
  # GET /car_action_logs/1.json
  def show
  end

  # GET /car_action_logs/new
  def new
    @car_action_log = CarActionLog.new
  end

  # GET /car_action_logs/1/edit
  def edit
  end

  # POST /car_action_logs
  # POST /car_action_logs.json
  def create
    @car_action_log = CarActionLog.new(car_action_log_params)

    respond_to do |format|
      if @car_action_log.save
        format.html { redirect_to @car_action_log, notice: 'Car action log was successfully created.' }
        format.json { render :show, status: :created, location: @car_action_log }
      else
        format.html { render :new }
        format.json { render json: @car_action_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /car_action_logs/1
  # PATCH/PUT /car_action_logs/1.json
  def update
    respond_to do |format|
      if @car_action_log.update(car_action_log_params)
        format.html { redirect_to @car_action_log, notice: 'Car action log was successfully updated.' }
        format.json { render :show, status: :ok, location: @car_action_log }
      else
        format.html { render :edit }
        format.json { render json: @car_action_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /car_action_logs/1
  # DELETE /car_action_logs/1.json
  def destroy
    @car_action_log.destroy
    respond_to do |format|
      format.html { redirect_to car_action_logs_url, notice: 'Car action log was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_car_action_log
      @car_action_log = CarActionLog.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def car_action_log_params
      params.require(:car_action_log).permit(:user_id, :speed, :direction, :latitude, :longitude, :activity, :heartrate)
    end
end
