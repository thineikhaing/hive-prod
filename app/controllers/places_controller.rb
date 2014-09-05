class PlacesController < ApplicationController
  def index
    @places = Place.all
  end

  def show
    @place = Place.find(params[:id])
    @visit = 0
    users_array = [ ]
    active_users_array = [ ]

    place_checked_in = Checkinplace.where(place_id: params[:id])

    place_checked_in.each do |pci|
      users_array.push(pci.user_id) unless users_array.include?(pci.user_id)
    end

    @visit = users_array.count
    places = Checkinplace.select(:user_id).uniq.where(place_id: params[:id])

    places.each do |ua|
      time_allowance = Time.now - 1000.minutes.ago
      user = User.find(ua.user_id)
      check_in = user.checkinplaces.where(place_id: params[:id]).last
      time_difference = Time.now - check_in.created_at

      if time_difference < time_allowance
        data = { user_id: user.id, username: user.username }
        active_users_array.push(data)
      end
    end

    @currentlyHere = active_users_array.count
    render :layout => false
  end
end
