require 'encounter/base'
require 'encounter/connection'
require 'encounter/player'
require 'encounter/team'

module Encounter
  # Class for game announce information
  #
  # @!attribute [r] domain
  #   @return [String] Domain name.
  # @!attribute [r] gid
  #   @return [Integer] Game id.
  # @!attribute [r] name
  #   @return [String] Game title.
  # @!attribute [r] authors
  #   @return [Array<Encounter::Player>] List of game authors.
  # @!attribute [r] start_time
  #   @return [String] Game start time.
  # @!attribute [r] end_time
  #   @return [String] Game end time.
  # @!attribute [r] money
  #   @return [String] Game price.
  # @!attribute [r] type
  #   @return [String] Game engine type.
  #     Possible values are _Real_, _Points_, _Virtual_, _Quiz_, _PhotoHunt_,
  #     _PhotoExtreme_, _Caching_, _WetWars_, _Competition_
  # @!attribute [r] limit
  #   @return [Integer] Maximal allowed players in team. 0 if unlimited.
  # @!attribute [r] description
  #   @return [String] Game description.
  # @!attribute [r] play_by
  #   @return [String] Possible values are _Team_, _Single_.
  # @!attribute [r] teams_accepted
  #   @return [Array<Encouter::Player>, Array<Encounter::Team>] List of accepted
  #     teams or players.
  # @!attribute [r] teams_waiting
  #   @return [Array<Encouter::Player>, Array<Encounter::Team>] List of teams or
  #     players waiting to be accepted.
  class Game < Encounter::Base
    include Encounter::HTMLParser

    attr_reader :domain, :gid

    lazy_attr_reader :name, :authors, :start_time, :end_time, :money,
                     :type, :limit, :description, :play_by,
                     :teams_accepted, :teams_waiting

    define_export_attrs :name, :domain, :gid, :authors, :start_time,
                        :end_time, :type, :money, :limit, :description,
                        :play_by, :teams_accepted, :teams_waiting

    define_parser_list :parse_authors, :parse_game_type, :parse_name,
                       :parse_limit, :parse_time, :parse_money,
                       :parse_description, :parse_players

    # @param [Encounter::Connection] conn
    # @param [Hash] params You can pass values in this parameters to predefine
    #   attributes. Any class attribute can be set.
    # @option params [String] :domain Domain name. <b>Required option</b>
    # @option params [Integer] :gid Game ID. <b>Required option</b>
    #
    # @todo Parse :play_by value
    #
    # @return [Encounter::Calendar] New object
    # @raise [ArgumentError] Raised if connection is not given
    # @raise [ArgumentError] Raised if :domain or :gid option is not defined
    def initialize(conn, params)
      raise ArgumentError, ':domain is needed' unless params.key? :domain
      raise ArgumentError, ':gid is needed' unless params.key? :gid

      super(conn, params)
    end

    private

    attr_reader :conn

    GAME_TYPES = %w[
      Real Virtual PhotoExtreme WetWars Caching PhotoHunt
      Unknown Points Competition Quiz Unknown
    ].freeze

    def parse_authors(table)
      as = table.css('a').select { |a| a['id'] && a['id'].match(/lnkAuthor$/) }
      {
        authors: as.map do |a|
                   Encounter::Player.new(
                     @conn,
                     uid: a['href'].match(/uid=(\d*)/).captures.first.to_i,
                     name: a.text
                   )
                 end
      }
    end

    def parse_game_type(table)
      type_id = table.css('img#ImgGameType').first['src']
                     .match(/type\.(\d*)\.gif/).captures.first.to_i
      { type: GAME_TYPES[type_id] }
    end

    def parse_name(table)
      { name: table.css('a#lnkGameTitle').first.text }
    end

    def parse_limit(table)
      item = table.css('span#spanMaxTeamPlayers').first
      { limit: item.nil? ? 0 : item.text.match(/(\d+)/).captures.first.to_i }
    end

    def parse_time(table)
      base = table.css('#GameDetail_YourTimeArea').first
      date = /(\d{2}\.\d{2}\.\d{4}\s\d{1,2}:\d{2}:\d{2})/
      {
        start_time: base.previous_element.text.match(date).captures.first,
        end_time: base.next_element.text.match(date).captures.first
      }
    end

    def parse_money(table)
      base = table.css('span#GameDetail_lblFeeType').first
      return { money: 0 } if base.nil?
      { money: "#{base.previous_element.text} #{base.text}" }
    end

    def parse_description(table)
      loop do
        table = table.next_element
        break if table.name == 'table'
      end
      { description: table.css('tr:eq(2)').inner_html }
    end

    def parse_players(table)
      base = table.css('div.hr').last.parent.parent.previous_element.css('div')
      accepted = parse_player_list base.last
      waiting = parse_player_list base.first if base.size > 1

      { teams_accepted: accepted, teams_waiting: waiting || [] }
    end

    def parse_player_list(div)
      div.css('a').map { |a| parse_player(a) }
    end

    def parse_player(a)
      usr = a['href'] =~ /UserDetails/
      klass = usr ? Encounter::Player : Encounter::Team
      tid = a['href'].match(/[ut]id=(\d+)/).captures.first.to_i
      params = { uid: tid } if usr
      params = { tid: tid } unless usr

      klass.new conn, params.merge(name: a.text)
    end

    def load_data
      html_page = @conn.page_get("http://#{domain}/GameDetails.aspx", gid: gid)
      @dom_page = Nokogiri::HTML(html_page)

      raise 'No such game' unless @dom_page.css('#boxCenterTopUsers').empty?
      assign_values parse_all(@dom_page.css('table.gameInfo').first)
    end
  end
end
