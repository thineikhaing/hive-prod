class CreateAppAdditionalFields < ActiveRecord::Migration[5.1]
  def change
    create_table :app_additional_fields do |t|

      t.integer :app_id
      t.string  :table_name
      t.string  :additional_column_name

      t.timestamps
    end
  end
end
