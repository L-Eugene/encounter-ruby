require 'faraday'
require 'faraday-cookie_jar'
require 'json'

# Module for all gem classes
module Encounter
  # Connection class
  #
  # @todo Allow UserAgent name override
  class Connection
    # @param [Hash] options ({})
    # @option options [String] :username Nickname or user id
    # @option options [String] :password
    # @option options [String] :domain Domain to connect.
    # @option options [String] :network ('Encounter') Network to login.
    #   Can be _Encounter_ or _QuestUa_.
    #
    # @example Connect using account
    #    Encounter::Connection.new(
    #      domain: 'test.en.cx',
    #      username: 'nickname',
    #      password: 'password'
    #    )
    #
    # @example Connect anonymous
    #    Encounter::Connection.new(domain: 'test.en.cx')
    def initialize(options = {})
      raise ArgumentError, ':domain is required option' if options[:domain].nil?
      options[:network] ||= 'Encounter'
      @options = options
      @conn = new_faraday_connection
      raise 'No such domain' unless domain_exist?
      authorize unless options[:username].nil? || options[:password].nil?
    end

    # Load specified url using GET method. Params added to URL
    #
    # @param [String] url
    # @param [Hash] params
    def page_get(url, params)
      @conn.get(url, params).body
    end

    private

    DDL_NETWORKS = {
      Encounter: 1,
      QuestUa: 2
    }.freeze

    def new_cookie_jar(cookie_file = nil)
      return HTTP::CookieJar.new if cookie_file.nil?
      HTTP::CookieJar.new.load(cookie_file)
    end

    def cookie_jar
      @cookie_jar ||= new_cookie_jar(@options[:cookie_file])
    end

    def new_faraday_connection
      Faraday.new(url: "http://#{@options[:domain]}") do |conn|
        conn.request :url_encoded
        conn.use :cookie_jar, jar: cookie_jar
        conn.adapter Faraday.default_adapter
      end
    end

    # Check if domain exist
    #
    # @return [Boolean]
    def domain_exist?
      !@conn.get('/').body.include? 'Domain name is unregistered!'
    end

    # Authorize on domain
    def authorize
      res = @conn.post do |req|
        req.url '/login/signin?json=1'
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          Login: @options[:username],
          Password:  @options[:password]
        }.to_json
      end
      res = JSON.parse res.body
      raise "Authorization error: #{res['Message']}" unless res['Error'].zero?
    end
  end
end
