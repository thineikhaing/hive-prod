class CreateFacades < ActiveRecord::Migration
  def change
    create_table :facades do |t|
      t.string :social_priority
      t.timestamps

      t.references :user
    end
  end
end
