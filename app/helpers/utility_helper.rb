module UtilityHelper
  def getHashValuefromString(data)
    data.sub! '{',''
    data.sub! '}',''
    hash = {}

    data.split(',').each do |pair|
      key,value = pair.split(/:/)
      hash[key] = value
    end

    return hash
  end
end
