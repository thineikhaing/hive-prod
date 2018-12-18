class UserFavLocation < ActiveRecord::Base

  belongs_to :user
  belongs_to :place

  def as_json(options=nil)
    if options[:content].present?      #return topic json with content information
      super(only: [:id, :user_id,:place_type,:updated_at], methods: [:place_information])
    else
      super(only: [:id, :user_id,:place_type,:updated_at], methods: [:place_information])
    end
  end

  def place_information
    if self.place_id.present? and self.place_id > 0
      place = Place.find(self.place_id)
      self.address.nil? ? address = place.address : address =  self.address
      self.name.nil? ? name = place.name : name = self.name
      self.img_url.nil? ? img_url = place.img_url : img_url = self.img_url
      {
        name: name, address: address,
        latitude: place.latitude, longitude: place.longitude,
        country: place.country, postal_code: place.postal_code,
        img_url: img_url
      }
    else
      { }
    end
  end


end
