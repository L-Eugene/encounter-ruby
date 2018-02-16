module Encounter
  # Game calendar parser class
  class Domain
    include HTMLParser

    # @param [Encounter::Connection] conn
    # @param [String] domain Taken from connection if not given
    # @return [Encounter::Calendar] New object
    # @raise [ArgumentError] Raised if connection is not given
    def initialize(conn, domain = nil)
      @domain = domain || conn.domain
      @conn = conn
    end

    def announces
      Nokogiri::HTML(@conn.page_get("http://#{@domain}/"))
              .css('#boxCenterComingGames #lnkGameTitle')
              .map { |a| parse_game(a) }
    end

    def players
      parse_domain_top '/UserList.aspx', 'lnkUserInfo'
    end

    def teams
      parse_domain_top '/Teams/TeamList.aspx', 'lnkTeamInfo'
    end

    def archive
      dom = Nokogiri::HTML(@conn.page_get("http://#{@domain}/Games.aspx"))
      max = parse_max_page(dom.css('#tdContentCenter').first, 'Games.aspx')
      1.upto(max).flat_map do |page|
        Nokogiri::HTML(@conn.page_get('/Games.aspx', page: page))
                .css('#lnkGameTitle').map { |a| parse_game(a) }
      end
    end

    def stars
      Nokogiri::HTML(@conn.page_get("http://#{@domain}/")).css('#tdLogo img')
              .first['src'].match(/en_logo(\d)s/).captures.first.to_i
    end

    private

    def parse_game(a)
      Encounter::Game.new(
        @conn,
        domain: @domain,
        gid: parse_url_id(a['href']),
        name: a.text
      )
    end

    def parse_domain_top(url, id_mask)
      dom = Nokogiri::HTML(@conn.page_get("http://#{@domain}#{url}"))
      max = parse_max_page(dom.css('#tdContentCenter').first, url)
      1.upto(max).flat_map { |page| parse_domain_top_page(url, id_mask, page) }
    end

    def parse_domain_top_page(url, id_mask, page)
      Nokogiri::HTML(@conn.page_get("http://#{@domain}#{url}", page: page))
              .css('#tdContentCenter a')
              .select { |a| a['id'] =~ /#{id_mask}$/ }
              .map { |a| parse_url_object(a) }
    end
  end
end
