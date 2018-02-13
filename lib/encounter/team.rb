require 'encounter/base'

module Encounter
  # Clas for Team information
  #
  # @!attribute [r] tid
  #   @return [Integer] Team ID.
  # @!attribute [r] name
  #   @return [String] Team name.
  # @!attribute [r] created at
  #   @return [String] Date when team was created.
  # @!attribute [r] players_count
  #   @return [Integer] Total number of players in team. Include captain,
  #     active players and reserve.
  # @!attribute [r] points
  #   @return [Float] Sum of all team player's points.
  # @!attribute [r] games_count
  #   @return [Integer] Total number of games played.
  # @!attribute [r] wins
  #   @return [Integer] Total number of games won.
  # @!attribute [r] anthem
  #   @return [String] URL to team anthem file.
  # @!attribute [r] website
  #   @return [String] URL to team site.
  # @!attribute [r] forum
  #   @return [String] URL to team external forum.
  # @!attribute [r] captain
  #   @return [Encounter::Player] Team captain.
  # @!attribute [r] active
  #   @return [Array<Encounter::Player>] List of active players.
  # @!attribute [r] reserve
  #   @return [Array<Encounter::Player>] List of reserve players.
  class Team < Encounter::Base
    include Encounter::HTMLParser

    attr_reader :tid

    lazy_attr_reader :name, :created_at, :players_count, :points, :games_count,
                     :wins, :anthem, :website, :forum, :captain, :active,
                     :reserve

    define_export_attrs :tid, :name, :created_at, :players, :points, :games,
                        :wins, :anthem, :website, :forum, :captain, :active,
                        :reserve

    define_parser_list :parse_attributes, :parse_anthem, :parse_urls,
                       :parse_captain, :parse_active, :parse_reserve

    # @param [Encounter::Connection] conn
    # @param [Hash] params You can pass values in this parameters to predefine
    #   attributes. Any class attribute can be set.
    # @option params [Integer] :tid Team ID. <b>Required option</b>
    #
    # @return [Encounter::Team] New object
    # @raise [ArgumentError] Raised if connection is not given
    # @raise [ArgumentError] Raised if :tid option is not defined
    def initialize(conn, params)
      raise ArgumentError, ':tid is needed' unless params.key? :tid

      super(conn, params)
    end

    # @private
    ID_PANEL = '#enTeamDetailsPanel_divInfo'.freeze
    # @private
    PARSER_OBJECTS = [
      { id: '#lnkTeamName', attr: 'name' },
      { id: "#{ID_PANEL} span:eq(1)", attr: 'created_at' },
      { id: "#{ID_PANEL} span:eq(2)", attr: 'players_count', type: 'i' },
      { id: "#{ID_PANEL} span:eq(3)", attr: 'points', type: 'f' },
      { id: "#{ID_PANEL} span:eq(4)", attr: 'games_count', type: 'i' },
      { id: "#{ID_PANEL} span:eq(5)", attr: 'wins', type: 'i' }
    ].freeze

    private

    def parse_anthem(obj)
      { anthem: obj.css("#{ID_PANEL} embed").map { |r| r['src'] }.join }
    end

    def parse_urls(obj)
      {
        website: obj.css('#lnkWebSite').map { |r| r['href'] }.join,
        forum: obj.css('#lnkForum').map { |r| r['href'] }.join
      }
    end

    def parse_captain(obj)
      obj = obj.css('#lnkCaptainInfo').first
      { captain: parse_url_object(obj) }
    end

    def parse_active(obj)
      {
        active: obj.css('#aspnetForm table:eq(2) tr td:eq(4) a').map do |a|
          parse_url_object(a)
        end
      }
    end

    def parse_reserve(obj)
      {
        reserve: obj.css('#aspnetForm table:eq(3) tr td:eq(4) a').map do |a|
          parse_url_object(a)
        end
      }
    end

    def load_data
      html_page = @conn.page_get('/Teams/TeamDetails.aspx', tid: tid)
      dom_page = Nokogiri::HTML(html_page)

      raise 'No such team' if dom_page.css('#lnkTeamName').empty?
      assign_values parse_all(dom_page.css('td#tdContentCenter').first)
    end
  end
end
