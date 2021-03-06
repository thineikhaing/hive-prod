class DeviseCreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table(:users) do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      #auth_token expiry date
      t.datetime :token_expiry_date

      t.string :username, null: false, default: ""
      t.string :device_id
      t.string :authentication_token
      t.string :avatar_url
      t.integer :role
      t.integer :point , default: 0
      #t.integer :honor_rating

      t.integer :flareMode,           :default => 0
      t.integer :alert_count,         :default => 3
      t.integer :paid_alert_count,    :default => 0
      t.float :credits,               :default => 0
      t.float :last_known_latitude,   :default => 0
      t.float :last_known_longitude,  :default => 0
      t.timestamp :check_in_time
      t.integer :profanity_counter,   :default => 0
      t.datetime :offence_date
      t.integer :positive_honor,      :default => 0
      t.integer :negative_honor,      :default => 0
      t.integer :honored_times,       :default => 0
      t.hstore :data

      t.timestamps
    end

    add_index :users, :authentication_token, unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end
end
