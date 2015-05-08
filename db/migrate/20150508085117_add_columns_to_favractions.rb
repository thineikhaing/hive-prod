class AddColumnsToFavractions < ActiveRecord::Migration
  def change
    add_column :favractions, :post_id, :integer
    add_column :favractions, :honor_to_owner, :integer, :default => 0
    add_column :favractions, :honor_to_doer, :integer, :default => 0

    User.create(email: "favrbot@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "FavrBot", role: 1)

  end
end
