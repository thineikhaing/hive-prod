class AddDeviceIdInAddFieldForFavr < ActiveRecord::Migration
  def change
    hive_app = HiveApplication.find_by_app_name('Favr')
    AppAdditionalField.create(app_id: hive_app.id,table_name: "User", additional_column_name: "device_id")

  end
end
