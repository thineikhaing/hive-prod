class AddHiveapplicationIdToPrivacyPolicy < ActiveRecord::Migration[5.0]
  def change
    add_column :privacy_policies, :hiveapplication_id, :integer
  end
end
