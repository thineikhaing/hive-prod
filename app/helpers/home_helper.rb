module HomeHelper
def lookup_key
  if Rails.env.development?
    carmmunicate_key = Carmmunicate_key::Development_Key
    favr_key = Favr_key::Development_Key
    meal_key = Mealbox_key::Development_Key
    socal_key = Socal_key::Development_Key

  elsif Rails.env.staging?
    carmmunicate_key = Carmmunicate_key::Staging_Key
    favr_key = Favr_key::Staging_Key
    meal_key = Mealbox_key::Staging_Key
    socal_key = Socal_key::Staging_Key

  else
    carmmunicate_key = Carmmunicate_key::Production_Key
    favr_key = Favr_key::Production_Key
    meal_key = Mealbox_key::Production_Key
    socal_key = Socal_key::Production_Key

  end

end
end
