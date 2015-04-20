require "test/unit"
require_relative "credentials"
require 'is24/location'
require 'is24/search'

class TestParseLog < Test::Unit::TestCase

  def test_basic_auth

      l = Location.new(47.6689, 9.5909) # tettnang
      client = Is24::Api.new(@@credentials)
      search = client.search
      flats = search.find_by_location_and_radius(l, 100)
      puts "flats #{flats.inspect}"
  end

end
