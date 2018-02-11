require 'encounter/base'

module Encounter
  # Team class
  class Team < Encounter::Base
    include Encounter::HTMLParser

    attr_reader :tid

    lazy_attr_reader :name, :created_at, :players, :points, :games, :wins,
                     :anthem, :website, :forum, :captain, :active, :reserve

    define_export_attrs :tid, :name, :created_at, :players, :points, :games,
                        :wins, :anthem, :website, :forum, :captain, :active,
                        :reserve

    define_parser_list :parse_attributes, :parse_anthem, :parse_urls, 
                       :parse_captain, :parse_active, :parse_reserve

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
      { id: "#{ID_PANEL} span:eq(2)", attr: 'players', type: 'i' },
      { id: "#{ID_PANEL} span:eq(3)", attr: 'points', type: 'f' },
      { id: "#{ID_PANEL} span:eq(4)", attr: 'games', type: 'i' },
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
      uid = obj.css('#lnkCaptainInfo').first['href'].match(/uid=(\d*)/)
               .captures.first.to_i
      { captain: Encounter::Player.new(@conn, uid: uid) }
    end

    def parse_active(obj)
      {
        active: obj.css("#aspnetForm table:eq(2) tr td:eq(4) a").map do |x|
                  Encounter::Player.new(
                    @conn,
                    uid: x['href'].match(/uid=(\d*)/).captures.first.to_i)
                end
      }
    end

    def parse_reserve(obj)
      {
        reserve: obj.css("#aspnetForm table:eq(3) tr td:eq(4) a").map do |x|
                    Encounter::Player.new(
                      @conn,
                      uid: x['href'].match(/uid=(\d*)/).captures.first.to_i)
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
