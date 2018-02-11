require 'encounter/base'

module Encounter
  # Team class
  class Team < Encounter::Base
    include Encounter::HTMLParser

    attr_reader :tid

    lazy_attr_reader :name, :created_at, :players, :points, :games, :wins,
                     :anthem, :website, :forum

    define_export_attrs :tid, :name

    define_parser_list :parse_attributes, :parse_anthem, :parse_urls

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

    def load_data
      html_page = @conn.page_get('/Teams/TeamDetails.aspx', tid: tid)
      dom_page = Nokogiri::HTML(html_page)

      raise 'No such team' if dom_page.css('#lnkTeamName').empty?
      assign_values parse_all(dom_page.css('td#tdContentCenter').first)
    end
  end
end
