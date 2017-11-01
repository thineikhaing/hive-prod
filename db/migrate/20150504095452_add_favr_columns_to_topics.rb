class AddFavrColumnsToTopics < ActiveRecord::Migration[5.1]
  def change
    add_column :topics, :extra_info, :string
    add_column :topics, :valid_start_date, :datetime
    add_column :topics, :valid_end_date, :datetime
    add_column :topics, :points, :integer

    add_column :topics, :free_points, :integer
    add_column :topics, :state, :integer
    add_column :topics, :title_indexes, :string
    add_column :topics, :checker, :integer

    add_column :topics, :given_time, :integer



  end
end
