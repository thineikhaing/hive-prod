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

RSpec.describe SgAccidentHistoriesController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # SgAccidentHistory. As you add validations to SgAccidentHistory, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SgAccidentHistoriesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all sg_accident_histories as @sg_accident_histories" do
      sg_accident_history = SgAccidentHistory.create! valid_attributes
      get :home, {}, valid_session
      expect(assigns(:sg_accident_histories)).to eq([sg_accident_history])
    end
  end

  describe "GET #show" do
    it "assigns the requested sg_accident_history as @sg_accident_history" do
      sg_accident_history = SgAccidentHistory.create! valid_attributes
      get :show, {:id => sg_accident_history.to_param}, valid_session
      expect(assigns(:sg_accident_history)).to eq(sg_accident_history)
    end
  end

  describe "GET #new" do
    it "assigns a new sg_accident_history as @sg_accident_history" do
      get :new, {}, valid_session
      expect(assigns(:sg_accident_history)).to be_a_new(SgAccidentHistory)
    end
  end

  describe "GET #edit" do
    it "assigns the requested sg_accident_history as @sg_accident_history" do
      sg_accident_history = SgAccidentHistory.create! valid_attributes
      get :edit, {:id => sg_accident_history.to_param}, valid_session
      expect(assigns(:sg_accident_history)).to eq(sg_accident_history)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new SgAccidentHistory" do
        expect {
          post :create, {:sg_accident_history => valid_attributes}, valid_session
        }.to change(SgAccidentHistory, :count).by(1)
      end

      it "assigns a newly created sg_accident_history as @sg_accident_history" do
        post :create, {:sg_accident_history => valid_attributes}, valid_session
        expect(assigns(:sg_accident_history)).to be_a(SgAccidentHistory)
        expect(assigns(:sg_accident_history)).to be_persisted
      end

      it "redirects to the created sg_accident_history" do
        post :create, {:sg_accident_history => valid_attributes}, valid_session
        expect(response).to redirect_to(SgAccidentHistory.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved sg_accident_history as @sg_accident_history" do
        post :create, {:sg_accident_history => invalid_attributes}, valid_session
        expect(assigns(:sg_accident_history)).to be_a_new(SgAccidentHistory)
      end

      it "re-renders the 'new' template" do
        post :create, {:sg_accident_history => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested sg_accident_history" do
        sg_accident_history = SgAccidentHistory.create! valid_attributes
        put :update, {:id => sg_accident_history.to_param, :sg_accident_history => new_attributes}, valid_session
        sg_accident_history.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested sg_accident_history as @sg_accident_history" do
        sg_accident_history = SgAccidentHistory.create! valid_attributes
        put :update, {:id => sg_accident_history.to_param, :sg_accident_history => valid_attributes}, valid_session
        expect(assigns(:sg_accident_history)).to eq(sg_accident_history)
      end

      it "redirects to the sg_accident_history" do
        sg_accident_history = SgAccidentHistory.create! valid_attributes
        put :update, {:id => sg_accident_history.to_param, :sg_accident_history => valid_attributes}, valid_session
        expect(response).to redirect_to(sg_accident_history)
      end
    end

    context "with invalid params" do
      it "assigns the sg_accident_history as @sg_accident_history" do
        sg_accident_history = SgAccidentHistory.create! valid_attributes
        put :update, {:id => sg_accident_history.to_param, :sg_accident_history => invalid_attributes}, valid_session
        expect(assigns(:sg_accident_history)).to eq(sg_accident_history)
      end

      it "re-renders the 'edit' template" do
        sg_accident_history = SgAccidentHistory.create! valid_attributes
        put :update, {:id => sg_accident_history.to_param, :sg_accident_history => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested sg_accident_history" do
      sg_accident_history = SgAccidentHistory.create! valid_attributes
      expect {
        delete :destroy, {:id => sg_accident_history.to_param}, valid_session
      }.to change(SgAccidentHistory, :count).by(-1)
    end

    it "redirects to the sg_accident_histories list" do
      sg_accident_history = SgAccidentHistory.create! valid_attributes
      delete :destroy, {:id => sg_accident_history.to_param}, valid_session
      expect(response).to redirect_to(sg_accident_histories_url)
    end
  end

end
