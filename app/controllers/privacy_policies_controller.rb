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
        format.html { redirect_to privacy_policies_path, notice: 'Privacy policy was successfully created.' }
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
        hiveId = params[:privacy_policy][:hiveapplication_id]
        hiveApp = HiveApplication.find(hiveId)
        appUsers = User.where("app_data ->'app_id#{hiveId}' = '#{hiveApp.api_key}'")
        to_device_id = []
        to_endpoint_arn = []
        user_id = []
        if appUsers.count > 0
          time_allowance = Time.now - 2.months.ago
          appUsers.each do |u|
            if u.check_in_time.present?
              time_difference = Time.now - u.check_in_time
              if time_difference < time_allowance
                  hash_array = u.data
                  if !u.data.nil?
                    device_id = hash_array["device_id"] if  hash_array["device_id"].present?
                    endpoint_arn = hash_array["endpoint_arn"] if  hash_array["endpoint_arn"].present?
                    to_device_id.push(device_id)
                    to_endpoint_arn.push(endpoint_arn)
                    user_id.push(u.id)
                  end
              end
            end
          end

          to_endpoint_arn.each do |arn|
            if arn.present?
              user_arn = arn
              sns = Aws::SNS::Client.new
              iphone_notification = {
                  aps: {
                      alert: "Notice: Privacy Policy is updated.",
                      sound: "default",
                      badge: 0,
                      extra:  {
                          policy: "update"
                        }
                  }
              }
              android_notification = {
                  data: {
                      message: "Notice: Privacy Policy is updated.",
                      badge: 0,
                      extra:  {
                          policy: "update"
                        }
                  }
              }
              sns_message = {
                  default: "Notice: Privacy Policy is updated.",
                  APNS_SANDBOX: iphone_notification.to_json,
                  APNS: iphone_notification.to_json,
                  GCM: android_notification.to_json
              }.to_json

              p "endpoint arn"
              p arn

              begin
                sns.publish(target_arn: user_arn, message: sns_message, message_structure:"json")
              rescue
                p "EndpointDisabledException or InvalidParameter"
              end
            end
          end
        end

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
