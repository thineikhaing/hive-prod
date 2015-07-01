class Country < ActiveRecord::Base

  attr_accessible :name, :tld, :cca2, :ccn3, :cca3, :currency, :calling_code, :capital, :alt_spellings,
      :relevance, :region, :subregion

end
