# encoding: UTF-8

require 'is24/logger'
require 'is24/search'

require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/response/mashify'
require 'cgi'

module Is24
  class Api
    include Is24::Logger

    API_ENDPOINT = "http://rest.immobilienscout24.de/restapi/api/search/v1.0/"
    API_OFFER_ENDPOINT = "http://rest.immobilienscout24.de/restapi/api/offer/v1.0/"
    API_AUTHORIZATION_ENDPOINT = "http://rest.immobilienscout24.de/restapi/security/"

    # TODO move in separate module
    MARKETING_TYPES = {
      "PURCHASE" => "Kauf",
      "PURCHASE_PER_SQM" => "Kaufpreis/ Quadratmeter",
      "RENT" => "Miete",
      "RENT_PER_SQM" => "Mietpreis/ Quadratmeter",
      "LEASE" => "Leasing",
      "LEASEHOLD" => "",
      "BUDGET_RENT" => "",
      "RENT_AND_BUY" => ""
    }

    PRICE_INTERVAL_TYPES = {
      "DAY" => "Tag",
      "WEEK" => "Woche",
      "MONTH" => "Monat",
      "YEAR" => "Jahr",
      "ONE_TIME_CHARGE" => "einmalig"
    }

    REAL_ESTATE_TYPES = {
      "APARTMENT_RENT" => "Wohnung Miete",
      "APARTMENT_BUY" => "Wohnung Kauf",
      "HOUSE_RENT" => "Haus Miete",
      "HOUSE_BUY" => "Haus Kauf",
      "GARAGE_RENT" => "Garage / Stellplatz Miete",
      "GARAGE_BUY" => "Garage / Stellplatz Kauf",
      "LIVING_RENT_SITE" => "Grundstück Wohnen Miete",
      "LIVING_BUY_SITE" => "Grundstück Wohnen Kauf",
      "TRADE_SITE" => "Grundstück Gewerbe",
      "HOUSE_TYPE" => "Typenhäuser",
      "FLAT_SHARE_ROOM" => "WG-Zimmer",
      "SENIOR_CARE" => "Altenpflege",
      "ASSISTED_LIVING" => "Betreutes Wohnen",
      "OFFICE" => "Büro / Praxis",
      "INDUSTRY" => "Hallen / Produktion",
      "STORE" => "Einzelhandel",
      "GASTRONOMY" => "Gastronomie / Hotel",
      "SPECIAL_PURPOSE" => "",
      "INVESTMENT" => "Gewerbeprojekte",
      "COMPULSORY_AUCTION" => "",
      "SHORT_TERM_ACCOMMODATION" => ""
    }

    # transforms, eg.
    # "SPECIAL_PURPOSE" => ""
    # to
    # "search:SpecialPurpose" => ""
    XSI_SEARCH_TYPES = lambda {
      return Hash[*REAL_ESTATE_TYPES.map{ |v|
          [
            "search:"+v.first.downcase.split("_").map!(&:capitalize).join,
            v[1]
          ]
        }.flatten
      ]
    }.()

    def self.format_marketing_type(marketing_type)
      MARKETING_TYPES[marketing_type] || ""
    end

    def self.format_price_interval_type(price_interval_type)
      PRICE_INTERVAL_TYPES[price_interval_type] || ""
    end

    def initialize( options = {} )
      logger "Initialized IS24 with options #{options}"

      @token = options[:token] || nil
      @secret = options[:secret] || nil
      @consumer_secret = options[:consumer_secret] || nil
      @consumer_key = options[:consumer_key] || nil

      raise "Missing Credentials!" if @consumer_secret.nil? || @consumer_key.nil?
    end

    def request_token( callback_uri )
      # TODO error handling
      response = connection(:authorization, callback_uri).get("oauth/request_token")

      body = response.body.split('&')
      response = {
        :oauth_token => CGI::unescape(body[0].split("=")[1]),
        :oauth_token_secret => CGI::unescape(body[1].split("=")[1]),
        :redirect_uri => "http://rest.immobilienscout24.de/restapi/security/oauth/confirm_access?#{body[0]}"
      }
    end

    def request_access_token( params = {} )
      # TODO error handling
      @oauth_verifier = params[:oauth_verifier]
      @token = params[:oauth_token]
      @secret = params[:oauth_token_secret]

      response = connection(:authorization).get("oauth/access_token")
      body = response.body.split('&')

      response = {
        :oauth_token => body[0].split('=')[1],
        :oauth_token_secret => CGI::unescape(body[1].split('=')[1]),
      }

      # set credentials in client
      @token = response[:oauth_token]
      @token_secret = response[:oauth_token_secret]

      # return access token and secret
      response
    end


    def expose(id)
      url = connection.build_url("expose/#{id}")

      response = connection.get("expose/#{id}")
      response.body["expose.expose"]
    end

    def list_exposes
      response = connection(:offer).get("user/me/realestate?publishchannel=IS24")
      response.body
    end

    def short_list
      response = connection.get("searcher/me/shortlist/0/entry")
      response.body["shortlist.shortlistEntries"].first["shortlistEntry"]
    end

    def search
      Is24::Search.new(connection(:offer))
    end

    protected

    def connection(connection_type = :default, callback_uri = nil)

      # set request defaults
      defaults = {
        :url => API_ENDPOINT,
        :headers => {
          :accept =>  'application/json',
          :user_agent => 'b\'nerd .media IS24 Ruby Client'}
      }

      defaults.merge!( {
        :url => API_AUTHORIZATION_ENDPOINT
      } ) if connection_type =~ /authorization/i

      defaults.merge!( {
        :url => API_OFFER_ENDPOINT
      } ) if connection_type =~ /offer/i


      # define oauth credentials
      oauth = {
        :consumer_key => @consumer_key,
        :consumer_secret => @consumer_secret,
        :token => @token,
        :token_secret => @secret
      }

      # merge callback_uri if present
      oauth.merge!( {
        :callback => callback_uri
      } ) if connection_type =~ /authorization/i && callback_uri

      # merge verifier if present
      oauth.merge!( {
        :verifier => @oauth_verifier
      } ) if connection_type =~ /authorization/i && @oauth_verifier

      puts "Init new Faraday connection"
      Faraday::Connection.new( defaults ) do |builder|
            builder.request :oauth, oauth
            builder.response :mashify
            builder.response :json unless connection_type =~ /authorization/i
            builder.adapter Faraday.default_adapter
          end
    end

  end
end
