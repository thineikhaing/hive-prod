class CreateHiveApplications < ActiveRecord::Migration
  def change
    create_table :hive_applications do |t|
      t.string :app_name
      t.string :app_type,  null: false
      t.string :api_key,  null: false
      t.string :description , :default => ""
      t.string :icon_url
      t.string :theme_color , :default => "#451734"
      t.integer :devuser_id, null: false

      t.timestamps
    end
  end
end
