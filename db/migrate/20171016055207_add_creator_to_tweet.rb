class AddCreatorToTweet < ActiveRecord::Migration[5.1]
  def change
    add_column :tweets, :creator, :string
  end
end
