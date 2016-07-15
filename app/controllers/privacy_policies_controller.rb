class PrivacyPoliciesController < ApplicationController
  before_action :set_privacy_policy, only: [:show, :edit, :update, :destroy]

  # GET /privacy_policies
  # GET /privacy_policies.json
  def index
    @privacy_policies = PrivacyPolicy.all
  end

  # GET /privacy_policies/1
  # GET /privacy_policies/1.json
  def show
  end

  # GET /privacy_policies/new
  def new
    @privacy_policy = PrivacyPolicy.new
  end

  # GET /privacy_policies/1/edit
  def edit
  end

  # POST /privacy_policies
  # POST /privacy_policies.json
  def create
    @privacy_policy = PrivacyPolicy.new(privacy_policy_params)

    respond_to do |format|
      if @privacy_policy.save
        format.html { redirect_to @privacy_policy, notice: 'Privacy policy was successfully created.' }
        format.json { render :show, status: :created, location: @privacy_policy }
      else
        format.html { render :new }
        format.json { render json: @privacy_policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /privacy_policies/1
  # PATCH/PUT /privacy_policies/1.json
  def update
    respond_to do |format|
      if @privacy_policy.update(privacy_policy_params)
        format.html { redirect_to @privacy_policy, notice: 'Privacy policy was successfully updated.' }
        format.json { render :show, status: :ok, location: @privacy_policy }
      else
        format.html { render :edit }
        format.json { render json: @privacy_policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /privacy_policies/1
  # DELETE /privacy_policies/1.json
  def destroy
    @privacy_policy.destroy
    respond_to do |format|
      format.html { redirect_to privacy_policies_url, notice: 'Privacy policy was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_privacy_policy
      @privacy_policy = PrivacyPolicy.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def privacy_policy_params
      params.require(:privacy_policy).permit(:title, :content,:hiveapplication_id)
    end
end
