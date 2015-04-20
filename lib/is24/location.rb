class Location
  attr_accessor :latitude
  attr_accessor :longitude

  def initialize(lat, long)
    @latitude = lat
    @longitude = long
  end

end