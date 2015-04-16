require "test/unit"
require_relative "credentials"

class TestParseLog < Test::Unit::TestCase

  def test_basic_auth
      client = Is24::Api.new(@credentials)
      request_token = client.request_token(callback_url)
      self.oauth_token = request_token[:oauth_token]
      self.oauth_token_secret = request_token[:oauth_token_secret]
      self.save!
  end

end
