class UserFavLocation < ActiveRecord::Base

  belongs_to :user
  belongs_to :place

  def as_json(options=nil)
    if options[:content].present?      #return topic json with content information
      super(only: [:id, :user_id,:place_type], methods: [:place_information])
    else
      super(only: [:id, :user_id,:place_type], methods: [:place_information])
    end
  end


  def place_information
    if self.place_id.present? and self.place_id > 0
      place = Place.find(self.place_id)

      name = self.name
      img_url = self.img_url

      name.nil? ? name = place.name : name = self.name
      img_url.nil? ? img_url = place.img_url : img_url = self.img_url

      { id: place.id, creator_id: place.user_id,
          name: name, address: place.address,
          latitude: place.latitude, longitude: place.longitude,
          country: place.country, postal_code: place.postal_code,
          img_url: img_url,locality: place.locality,
          source: place.source, source_id: place.source_id}
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil ,
          custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end
  end


end
