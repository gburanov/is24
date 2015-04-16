require "test/unit"
require_relative "credentials"

class TestParseLog < Test::Unit::TestCase

  def test_basic_auth


      client = Is24::Api.new(@@credentials)

      search = client.search
  end

end
