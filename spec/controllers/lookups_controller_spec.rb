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

RSpec.describe LookupsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Lookup. As you add validations to Lookup, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # LookupsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all lookups as @lookups" do
      lookup = Lookup.create! valid_attributes
      get :home, {}, valid_session
      expect(assigns(:lookups)).to eq([lookup])
    end
  end

  describe "GET #show" do
    it "assigns the requested lookup as @lookup" do
      lookup = Lookup.create! valid_attributes
      get :show, {:id => lookup.to_param}, valid_session
      expect(assigns(:lookup)).to eq(lookup)
    end
  end

  describe "GET #new" do
    it "assigns a new lookup as @lookup" do
      get :new, {}, valid_session
      expect(assigns(:lookup)).to be_a_new(Lookup)
    end
  end

  describe "GET #edit" do
    it "assigns the requested lookup as @lookup" do
      lookup = Lookup.create! valid_attributes
      get :edit, {:id => lookup.to_param}, valid_session
      expect(assigns(:lookup)).to eq(lookup)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Lookup" do
        expect {
          post :create, {:lookup => valid_attributes}, valid_session
        }.to change(Lookup, :count).by(1)
      end

      it "assigns a newly created lookup as @lookup" do
        post :create, {:lookup => valid_attributes}, valid_session
        expect(assigns(:lookup)).to be_a(Lookup)
        expect(assigns(:lookup)).to be_persisted
      end

      it "redirects to the created lookup" do
        post :create, {:lookup => valid_attributes}, valid_session
        expect(response).to redirect_to(Lookup.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved lookup as @lookup" do
        post :create, {:lookup => invalid_attributes}, valid_session
        expect(assigns(:lookup)).to be_a_new(Lookup)
      end

      it "re-renders the 'new' template" do
        post :create, {:lookup => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested lookup" do
        lookup = Lookup.create! valid_attributes
        put :update, {:id => lookup.to_param, :lookup => new_attributes}, valid_session
        lookup.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested lookup as @lookup" do
        lookup = Lookup.create! valid_attributes
        put :update, {:id => lookup.to_param, :lookup => valid_attributes}, valid_session
        expect(assigns(:lookup)).to eq(lookup)
      end

      it "redirects to the lookup" do
        lookup = Lookup.create! valid_attributes
        put :update, {:id => lookup.to_param, :lookup => valid_attributes}, valid_session
        expect(response).to redirect_to(lookup)
      end
    end

    context "with invalid params" do
      it "assigns the lookup as @lookup" do
        lookup = Lookup.create! valid_attributes
        put :update, {:id => lookup.to_param, :lookup => invalid_attributes}, valid_session
        expect(assigns(:lookup)).to eq(lookup)
      end

      it "re-renders the 'edit' template" do
        lookup = Lookup.create! valid_attributes
        put :update, {:id => lookup.to_param, :lookup => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested lookup" do
      lookup = Lookup.create! valid_attributes
      expect {
        delete :destroy, {:id => lookup.to_param}, valid_session
      }.to change(Lookup, :count).by(-1)
    end

    it "redirects to the lookups list" do
      lookup = Lookup.create! valid_attributes
      delete :destroy, {:id => lookup.to_param}, valid_session
      expect(response).to redirect_to(lookups_url)
    end
  end

end
