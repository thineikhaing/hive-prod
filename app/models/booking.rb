class Booking < ApplicationRecord
    belongs_to :user

    def as_json(options=nil)
        if options[:content].present?      #return topic json with content information
            super(only: [:id, :user_id,:booking_date,:checkin_time,:checkout_time,:updated_at], methods: [:place_information])
        else
            super(only: [:id, :user_id,:booking_date,:checkin_time,:checkout_time,:updated_at], methods: [:place_information])
        end
    end
    
    def place_information
        if self.place_id.present? and self.place_id > 0
            place = Place.find(self.place_id)
            
            {
            name: place.name, address: place.address,
            latitude: place.latitude, longitude: place.longitude,
            country: place.country
            }
        else
            { }
        end
    end

    def username
        User.find_by_id(self.user_id).username
    end

 
end
