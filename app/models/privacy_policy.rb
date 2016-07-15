class PrivacyPolicy < ActiveRecord::Base
  # belongs_to :hive_application   , :foreign_key => 'hiveapplication_id'
  belongs_to :application , class_name: "HiveApplication", foreign_key: "hiveapplication_id",primary_key: :id
end
