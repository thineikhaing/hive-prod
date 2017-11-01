class CreateIncidentHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :incident_histories do |t|
      t.integer :host_id
      t.integer :peer_id
      t.hstore :host_data
      t.hstore :peer_data

      t.timestamps
    end

    carmmic_app = HiveApplication.find_by_app_name("Carmmunicate")

    if carmmic_app.present?
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "IncidentHistory", additional_column_name: "latitude")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "IncidentHistory", additional_column_name: "longitude")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "IncidentHistory", additional_column_name: "speed")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "IncidentHistory", additional_column_name: "direction")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "IncidentHistory", additional_column_name: "activity")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "IncidentHistory", additional_column_name: "heartrate")
    end

  end
end
