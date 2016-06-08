class AddRtPonintsToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :start_place_id, :integer , default: 0
    add_column :topics, :end_place_id, :integer , default: 0
  end
end
