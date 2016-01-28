class UserFavLocationsController < ApplicationController
  before_action :set_user_fav_location, only: [:show, :edit, :update, :destroy]

  # GET /user_fav_locations
  # GET /user_fav_locations.json
  def index
    @user_fav_locations = UserFavLocation.all
  end

  # GET /user_fav_locations/1
  # GET /user_fav_locations/1.json
  def show
  end

  # GET /user_fav_locations/new
  def new
    @user_fav_location = UserFavLocation.new
  end

  # GET /user_fav_locations/1/edit
  def edit
  end

  # POST /user_fav_locations
  # POST /user_fav_locations.json
  def create
    @user_fav_location = UserFavLocation.new(user_fav_location_params)

    respond_to do |format|
      if @user_fav_location.save
        format.html { redirect_to @user_fav_location, notice: 'User fav location was successfully created.' }
        format.json { render :show, status: :created, location: @user_fav_location }
      else
        format.html { render :new }
        format.json { render json: @user_fav_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_fav_locations/1
  # PATCH/PUT /user_fav_locations/1.json
  def update
    respond_to do |format|
      if @user_fav_location.update(user_fav_location_params)
        format.html { redirect_to @user_fav_location, notice: 'User fav location was successfully updated.' }
        format.json { render :show, status: :ok, location: @user_fav_location }
      else
        format.html { render :edit }
        format.json { render json: @user_fav_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_fav_locations/1
  # DELETE /user_fav_locations/1.json
  def destroy
    @user_fav_location.destroy
    respond_to do |format|
      format.html { redirect_to user_fav_locations_url, notice: 'User fav location was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_fav_location
      @user_fav_location = UserFavLocation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_fav_location_params
      params.require(:user_fav_location).permit(:user_id, :place_id, :place_type)
    end
end
