class Api::PlacesController < ApplicationController
  def create

    if current_user.present?

      params[:name].present? ? name = params[:name] : name = nil
      params[:category].present? ? category = params[:category] : category = nil
      params[:address].present? ? address = params[:address] : address = nil
      params[:latitude].present? ? latitude = params[:latitude] : latitude = nil
      params[:longitude].present? ? longitude = params[:longitude] : longitude = nil
      params[:locality].present? ? locality = params[:locality] : locality=nil
      params[:region].present? ? region = params[:region] : region=nil
      params[:neighbourhood].present? ? neighbourhood = params[:neighbourhood] : neighbourhood=nil
      params[:country].present? ? country = params[:country] : country=nil
      params[:postcode].present? ? postcode = params[:postcode] : postcode=nil
      params[:img_url].present? ? img_url = params[:img_url] : img_url = nil
      params[:website_url].present? ? website_url= params[:website_url] : website_url = nil
      params[:chain_name].present? ? chain_name = params[:chain_name] : chain_name = nil
      params[:contact_number].present? ? contact_number= params[:contact_number] : contact_number = nil
      params[:source].present? ? source = params[:source] : source = nil
      params[:source_id].present? ? source_id = params[:source_id] : source_id = nil

      place = Place.create(name: name, category: category, address: address, locality: locality, region: region, neighbourhood: neighbourhood,country: country,postal_code: postcode, website_url: website_url,chain_name: chain_name, contact_number: contact_number,img_url: img_url, source: source, source_id: source_id,user_id: current_user.id, latitude: latitude, longitude: longitude)

      render json: { place: place}
    end

  end

  def retrieve_places
    data_array = [ ]
    factual_data_array = [ ]

    if params[:latitude].present? and params[:longitude].present? and params[:radius].present?
      places = Place.nearest(params[:latitude], params[:longitude], params[:radius])

      places.each do |pl|
        data_array.push(pl)
      end

      factual = Factual.new(Factual_Const::Key, Factual_Const::Secret)
      query = factual.table("global").geo("$circle" => {"$center" => [params[:latitude], params[:longitude]], "$meters" => params[:radius].to_f*1000})

      query.each do |q|
        data = { name: q["name"], latitude: q["latitude"], longitude: q["longitude"], address: q["address"], source: 3, user_id: nil, username: nil, source_id: q["factual_id"] }
        factual_data_array.push(data)
      end

      data_array.each do |da|
        factual_data_array.each do |fda|
          factual_data_array.delete(fda) if da[:name] == fda[:name]
        end
      end

      data_array = data_array + factual_data_array

      render json: { places: data_array}
    end
  end
end