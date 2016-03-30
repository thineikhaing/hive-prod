class Roundtrip  < ActiveRecord::Base
  def weekday?
      (1..5).include?(wday)
  end

  def is_weekend?(wday)
    [5, 6, 7].include?(wday)
  end



end