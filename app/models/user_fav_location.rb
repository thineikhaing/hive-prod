class UserFavLocation < ActiveRecord::Base

  belongs_to :user
  belongs_to :place

  def as_json(options=nil)
    if options[:content].present?      #return topic json with content information
      super(only: [:id, :user_id,:place_id,:place_type], methods: [:user_information,:place_information])
    else
      super(only: [:id, :user_id,:place_id,:place_type], methods: [:user_information,:place_information])
    end
  end


  def place_information
    if self.place_id.present? and self.place_id > 0
      place = Place.find(self.place_id)
      { id: place.id, name: place.name, latitude: place.latitude, longitude: place.longitude, address: place.address, category: place.category, source: place.source, source_id: place.source_id, user_id: place.user_id, country: place.country, postal_code: place.postal_code, chain_name: place.chain_name, contact_number: place.contact_number, img_url: place.img_url,locality: place.locality, region: place.region, neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end
  end

  def user_information
    if self.user_id.present?
      user = User.find(self.user_id)
      {id: user.id, username: user.username}
    end
  end


end
