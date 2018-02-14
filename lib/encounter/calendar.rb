require 'nokogiri'
require 'csv'
require 'encounter/parser'
require 'encounter/game'

module Encounter
  # Game calendar parser class
  class Calendar
    include Encounter::HTMLParser

    # @param [Encounter::Connection] conn
    # @return [Encounter::Calendar] New object
    # @raise [ArgumentError] Raised if connection is not given
    def initialize(conn)
      unless conn.instance_of? Encounter::Connection
        raise ArgumentError, 'Connection needed'
      end
      @conn = conn
    end

    # Method to load game announces by filter
    #
    # @param [Hash] filter
    # @option filter [String] :status One of _Coming_, _Active_, _Finished_.
    #   *At the moment Finished status is not supported.*
    # @option filter [String] :zone Game engine type.
    #   Possible values are _Real_, _Points_, _Virtual_, _Quiz_, _PhotoHunt_,
    #   _PhotoExtreme_, _Caching_, _WetWars_, _Competition_
    # @option filter [Integer] :cntr Country ID
    # @option filter [Integer] :p Region ID
    # @option filter [Integer] :t City ID
    def load_announces(filter = DEFAULT_FILTER)
      # TODO: raise exception if only filter is zone=all
      load_page filter
      res = parse_calendar_page
      @page_number = parse_page_count
      return res if filter.key? :page
      2.upto(@page_number) do |page_num|
        load_page(filter.merge(page: page_num))
        res += parse_calendar_page
      end
      res
    end

    # Method to load list of countries, regions and cities
    # available to use in filters.
    #
    # @return [Array<Hash>] Every item contains _id_, _name_ and _regions_
    #   fields. _regions_ is Array of Hash, containig _id_, _name_ and
    #   _cities_. _cities_ is Array of Has with _id_ and _name_ items.
    def load_regions
      return @regions if @regions
      load_page DEFAULT_FILTER unless dom_page
      @regions = parse_countries
    end

    private

    # Default value for {.load_announces} parameter.
    DEFAULT_FILTER = { status: 'Coming', zone: 'Real' }.freeze
    CALENDAR_URL = '/GameCalendar.aspx'.freeze
    GEOGRAPHY_URL = '/ALoader/Geography.aspx'.freeze

    attr_accessor :html_page
    attr_reader   :dom_page

    define_parser_list :parse_domain, :parse_date, :parse_name, :parse_gid,
                       :parse_authors, :parse_money

    # Collect Game objects from HTML page
    #
    # @return [Array<Encounter::Game>] list of games from given page.
    def parse_calendar_page
      dom_page.css('table.tabCalContainer tr.infoRow').map do |tr|
        Encounter::Game.new(@conn, parse_all(tr))
      end
    end

    # Get game domain name
    #
    # @return [Hash] with _domain_ key.
    def parse_domain(tr)
      { domain: tr.css('td:eq(4) a').first['href'] }
    end

    # Get game date
    #
    # @return [Hash] with _start_time_ key.
    def parse_date(tr)
      {
        start_time: tr.css('td:eq(5)').first
                      .css('script').text
                      .match(/DateToLocalString\(\'(.*)\'\)/)
                      .captures.first
      }
    end

    # Get game name
    #
    # @return [Hash] with _name_ key.
    def parse_name(tr)
      { name: tr.css('td:eq(6) a:eq(1)').text }
    end

    # Get game id
    #
    # @return [Hash] with _gid_ key.
    def parse_gid(tr)
      { gid: parse_url_id(tr.css('td:eq(6) a').first['href']) }
    end

    # Get game id
    #
    # @return [Hash] with _gid_ key.
    def parse_authors(tr)
      {
        authors: tr.css('td:eq(7)').first.css('a').map do |a|
          parse_url_object(a)
        end
      }
    end

    # Get game price
    #
    # @return [Hash] with _money_ key.
    def parse_money(tr)
      { money: tr.css('td:eq(8) a').text }
    end

    # Return number of pages from HTML
    def parse_page_count
      dom_page.css('.tabCalContainer table:eq(3) a').size + 1
    end

    def parse_countries
      dom_page.css('#ddlCountry option:gt(1)').map do |x|
        parse_id_name([x['value'], x.text]).merge(
          regions: parse_regions(x['value'])
        )
      end
    end

    def parse_regions(cid)
      @conn.page_get(GEOGRAPHY_URL, c: cid, wse: 1).each_line.map do |r|
        r = r.split(';')
        next unless r.size == 2 && r.first =~ /\d+/
        parse_id_name(r).merge(cities: parse_cities(r.first))
      end.compact
    end

    def parse_cities(rid)
      @conn.page_get(GEOGRAPHY_URL, p: rid, wse: 1).each_line.map do |r|
        r = r.split(';')
        next unless r.size == 2 && r.first =~ /\d+/
        parse_id_name(r) if r.first.to_i > 0
      end.compact
    end

    def parse_id_name(r)
      { id: r.first.to_i, name: r.last.strip }
    end

    def load_page(filters)
      @html_page = @conn.page_get(CALENDAR_URL, filters)
      @dom_page = Nokogiri::HTML(html_page)
    end
  end
end
