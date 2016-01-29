class CreatePrivacyPolicies < ActiveRecord::Migration
  def change
    create_table :privacy_policies do |t|
      t.string :title
      t.text :content

      t.timestamps null: false
    end
  end
end
