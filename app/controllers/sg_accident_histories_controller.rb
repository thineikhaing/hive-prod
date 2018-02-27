class SgAccidentHistoriesController < ApplicationController
  before_action :set_sg_accident_history, only: [:show, :edit, :update, :destroy]

  # GET /sg_accident_histories
  # GET /sg_accident_histories.json
  def index
    @sg_accident_histories = SgAccidentHistory.all.order("accident_datetime desc").page params[:page]
  end

  # GET /sg_accident_histories/1
  # GET /sg_accident_histories/1.json
  def show
  end

  # GET /sg_accident_histories/new
  def new
    @sg_accident_history = SgAccidentHistory.new
  end

  # GET /sg_accident_histories/1/edit
  def edit
  end

  # POST /sg_accident_histories
  # POST /sg_accident_histories.json
  def create
    @sg_accident_history = SgAccidentHistory.new(sg_accident_history_params)

    respond_to do |format|
      @sg_accident_history.type ="HeavyTraffic"
      @sg_accident_history.accident_datetime = Time.now

      if @sg_accident_history.save
        SgAccidentHistory.send_traffic_noti(@sg_accident_history)

        format.html { redirect_to sg_accident_histories_url, notice: 'Sg accident history was successfully created.' }
        format.json { render :index, status: :created, location: sg_accident_histories_url }
      else
        format.html { render :new }
        format.json { render json: @sg_accident_history.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sg_accident_histories/1
  # PATCH/PUT /sg_accident_histories/1.json
  def update
    respond_to do |format|
      if @sg_accident_history.update(sg_accident_history_params)
        format.html { redirect_to @sg_accident_history, notice: 'Sg accident history was successfully updated.' }
        format.json { render :show, status: :ok, location: @sg_accident_history }
      else
        format.html { render :edit }
        format.json { render json: @sg_accident_history.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sg_accident_histories/1
  # DELETE /sg_accident_histories/1.json
  def destroy
    @sg_accident_history.destroy
    respond_to do |format|
      format.html { redirect_to sg_accident_histories_url, notice: 'Sg accident history was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sg_accident_history
      @sg_accident_history = SgAccidentHistory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sg_accident_history_params
      params.require(:sg_accident_history).permit(:type, :message, :accident_datetime, :latitude, :longitude, :summary, :notify)
    end
end
