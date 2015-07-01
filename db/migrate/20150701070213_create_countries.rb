class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name
      t.string :locale_name
      t.string :cca2
      t.string :ccn3
      t.string :cca3
      t.string :tld
      t.string :currency
      t.integer :calling_code
      t.string :capital
      t.string :alt_spellings
      t.float :relevance
      t.string :region
      t.string :subregion
      t.timestamps
    end
  end
end
