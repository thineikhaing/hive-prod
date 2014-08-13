class CreateHiveApplications < ActiveRecord::Migration
  def change
    create_table :hive_applications do |t|
      t.string :app_name
      t.string :app_type
      t.string :api_key
      t.string :description , :default => ""
      t.string :icon_url
      t.string :theme_color , :default => ""
      t.integer :devuser_id

      t.timestamps
    end
  end
end
