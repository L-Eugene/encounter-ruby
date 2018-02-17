module Encounter
  # Game calendar parser class
  class Domain
    include HTMLParser

    # @param [Encounter::Connection] conn
    # @param [String] domain Taken from connection if not given.
    #
    # @return [Encounter::Domain] New object
    # @raise [ArgumentError] Raised if connection is not given
    def initialize(conn, domain = nil)
      @domain = domain || conn.domain
      @conn = conn
      @cal_url = "http://#{@domain}/GameCalendar.aspx"
    end

    # Returns coming games list from domain
    #
    # @return [Array<Encounter::Game>]
    def announces
      load_page("http://#{@domain}/").css('#boxCenterComingGames #lnkGameTitle')
                                     .map { |a| parse_game(a) }
    end

    # Returns domain player list
    #
    # @return [Array<Encounter::Player>]
    def players
      parse_domain_top '/UserList.aspx', 'lnkUserInfo'
    end

    # Returns domain team list
    #
    # @return [Array<Encounter::Team>]
    def teams
      parse_domain_top '/Teams/TeamList.aspx', 'lnkTeamInfo'
    end

    # Returns past game list from domain
    #
    # @return [Array<Encounter::Game>]
    def archive
      dom = load_page("http://#{@domain}/Games.aspx")
      max = parse_max_page(dom.css('#tdContentCenter').first, 'Games.aspx')
      1.upto(max).flat_map do |page|
        load_page('/Games.aspx', page: page).css('#lnkGameTitle')
                                            .map { |a| parse_game(a) }
      end
    end

    # Return domain rating. It is integer number between 0 and 7.
    #
    # @return [Integer]
    def stars
      load_page("http://#{@domain}/").css('#tdLogo img').first['src']
                                     .match(/en_logo(\d)s/).captures.first.to_i
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
    def calendar(filter = { status: 'Coming', zone: 'Real' })
      page = load_page @cal_url, filter
      page_number = parse_max_page(page, 'GameCalendar.aspx')
      return parse_calendar_page(page) if filter.key? :page
      1.upto(page_number).flat_map do |i|
        page = load_page @cal_url, filter.merge(page: i)
        parse_calendar_page(page)
      end
    end

    def calendar_regions
      @regions ||= parse_countries(load_page(@cal_url))
    end

    # @private
    PARSER_OBJECTS = [
      { id: 'td:eq(6) a:eq(1)', attr: 'name' },
      { id: 'td:eq(8) a', attr: 'money' },
      {
        id: 'td:eq(5) script', attr: 'start_time',
        proc: proc { |r| r.match(/ToLocalString\(\'(.*)\'\)/).captures.first }
      }
    ].freeze

    private

    GEOGRAPHY_URL = '/ALoader/Geography.aspx'.freeze

    def parse_game(a)
      Encounter::Game.new(
        @conn, domain: @domain, gid: parse_url_id(a['href']), name: a.text
      )
    end

    def parse_domain_top(url, id_mask)
      dom = load_page("http://#{@domain}#{url}")
      max = parse_max_page(dom.css('#tdContentCenter').first, url)
      1.upto(max).flat_map { |page| parse_domain_top_page(url, id_mask, page) }
    end

    def parse_domain_top_page(url, id_mask, page)
      load_page("http://#{@domain}#{url}", page: page)
        .css('#tdContentCenter a').select { |a| a['id'] =~ /#{id_mask}$/ }
        .map { |a| parse_url_object(a) }
    end

    def parse_countries(dom)
      dom.css('#ddlCountry option:gt(1)').map do |x|
        parse_id_name([x['value'], x.text]).merge(
          regions: parse_regions(x['value'])
        )
      end
    end

    def parse_regions(cid)
      parse_cvs_pair(
        GEOGRAPHY_URL, { c: cid, wse: 1 },
        proc { |r| parse_id_name(r).merge(cities: parse_cities(r.first)) }
      )
    end

    def parse_cities(rid)
      parse_cvs_pair(
        GEOGRAPHY_URL, { p: rid, wse: 1 },
        proc { |r| parse_id_name(r) if r.first.to_i > 0 }
      )
    end

    def parse_calendar_page(obj)
      obj.css('table.tabCalContainer tr.infoRow').map do |tr|
        Encounter::Game.new(@conn, parse_calendar_game(tr))
      end
    end

    def parse_calendar_game(tr)
      parse_attributes(tr).merge(
        domain: tr.css('td:eq(4) a').first['href'].match(%r{\/([0-9a-z\.]+)\/})
                  .captures.first,
        gid: parse_url_id(tr.css('td:eq(6) a').first['href']),
        authors: parse_calendar_authors(tr)
      )
    end

    def parse_calendar_authors(tr)
      tr.css('td:eq(7)').first.css('a').map { |a| parse_url_object a }
    end
  end
end
