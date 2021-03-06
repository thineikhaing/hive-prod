require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe PrivacyPoliciesController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # PrivacyPolicy. As you add validations to PrivacyPolicy, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PrivacyPoliciesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all privacy_policies as @privacy_policies" do
      privacy_policy = PrivacyPolicy.create! valid_attributes
      get :home, {}, valid_session
      expect(assigns(:privacy_policies)).to eq([privacy_policy])
    end
  end

  describe "GET #show" do
    it "assigns the requested privacy_policy as @privacy_policy" do
      privacy_policy = PrivacyPolicy.create! valid_attributes
      get :show, {:id => privacy_policy.to_param}, valid_session
      expect(assigns(:privacy_policy)).to eq(privacy_policy)
    end
  end

  describe "GET #new" do
    it "assigns a new privacy_policy as @privacy_policy" do
      get :new, {}, valid_session
      expect(assigns(:privacy_policy)).to be_a_new(PrivacyPolicy)
    end
  end

  describe "GET #edit" do
    it "assigns the requested privacy_policy as @privacy_policy" do
      privacy_policy = PrivacyPolicy.create! valid_attributes
      get :edit, {:id => privacy_policy.to_param}, valid_session
      expect(assigns(:privacy_policy)).to eq(privacy_policy)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new PrivacyPolicy" do
        expect {
          post :create, {:privacy_policy => valid_attributes}, valid_session
        }.to change(PrivacyPolicy, :count).by(1)
      end

      it "assigns a newly created privacy_policy as @privacy_policy" do
        post :create, {:privacy_policy => valid_attributes}, valid_session
        expect(assigns(:privacy_policy)).to be_a(PrivacyPolicy)
        expect(assigns(:privacy_policy)).to be_persisted
      end

      it "redirects to the created privacy_policy" do
        post :create, {:privacy_policy => valid_attributes}, valid_session
        expect(response).to redirect_to(PrivacyPolicy.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved privacy_policy as @privacy_policy" do
        post :create, {:privacy_policy => invalid_attributes}, valid_session
        expect(assigns(:privacy_policy)).to be_a_new(PrivacyPolicy)
      end

      it "re-renders the 'new' template" do
        post :create, {:privacy_policy => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested privacy_policy" do
        privacy_policy = PrivacyPolicy.create! valid_attributes
        put :update, {:id => privacy_policy.to_param, :privacy_policy => new_attributes}, valid_session
        privacy_policy.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested privacy_policy as @privacy_policy" do
        privacy_policy = PrivacyPolicy.create! valid_attributes
        put :update, {:id => privacy_policy.to_param, :privacy_policy => valid_attributes}, valid_session
        expect(assigns(:privacy_policy)).to eq(privacy_policy)
      end

      it "redirects to the privacy_policy" do
        privacy_policy = PrivacyPolicy.create! valid_attributes
        put :update, {:id => privacy_policy.to_param, :privacy_policy => valid_attributes}, valid_session
        expect(response).to redirect_to(privacy_policy)
      end
    end

    context "with invalid params" do
      it "assigns the privacy_policy as @privacy_policy" do
        privacy_policy = PrivacyPolicy.create! valid_attributes
        put :update, {:id => privacy_policy.to_param, :privacy_policy => invalid_attributes}, valid_session
        expect(assigns(:privacy_policy)).to eq(privacy_policy)
      end

      it "re-renders the 'edit' template" do
        privacy_policy = PrivacyPolicy.create! valid_attributes
        put :update, {:id => privacy_policy.to_param, :privacy_policy => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested privacy_policy" do
      privacy_policy = PrivacyPolicy.create! valid_attributes
      expect {
        delete :destroy, {:id => privacy_policy.to_param}, valid_session
      }.to change(PrivacyPolicy, :count).by(-1)
    end

    it "redirects to the privacy_policies list" do
      privacy_policy = PrivacyPolicy.create! valid_attributes
      delete :destroy, {:id => privacy_policy.to_param}, valid_session
      expect(response).to redirect_to(privacy_policies_url)
    end
  end

end
