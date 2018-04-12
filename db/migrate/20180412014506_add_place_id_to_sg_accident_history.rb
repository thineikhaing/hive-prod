class AddPlaceIdToSgAccidentHistory < ActiveRecord::Migration[5.1]
  def change
    add_column :sg_accident_histories, :place_id, :integer
  end
end
