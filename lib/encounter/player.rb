module Encounter
  # Class for player information
  #
  # @!attribute [r] uid
  #   @return [Integer] User ID
  # @!attribute [r] name
  #   @return [String] Player nickname
  # @!attribute [r] avatar
  #   @return [String] URL to user's avatar
  # @!attribute [r] points
  #   @return [Integer] Game points
  # @!attribute [r] first_name
  #   @return [String] First name
  # @!attribute [r] patronymic_name
  #   @return [String] Patronymic name
  # @!attribute [r] last_name
  #   @return [String] Last name
  # @!attribute [r] country
  #   @return [String] Player's home country
  # @!attribute [r] region
  #   @return [String] Player's home region/province
  # @!attribute [r] city
  #   @return [String] Player's home city
  # @!attribute [r] sex
  #   @return [Symbol] Player's gender. Either _:male_ or _:female_
  # @!attribute [r] birthday
  #   @return [String] Birthday date
  # @!attribute [r] height
  #   @return [Integer] Height in cm
  # @!attribute [r] weight
  #   @return [Integer] Weight in kg
  # @!attribute [r] email
  #   @return [String] E-Mail address
  # @!attribute [r] mobile_phone
  #   @return [String] Mobile phone number
  # @!attribute [r] website
  #   @return [String] Website URL
  # @!attribute [r] skype
  #   @return [String] Skype username
  # @!attribute [r] driver_license
  #   @return [Array<Symbol>] Array of driver license categories
  # @!attribute [r] transport
  #   @return [Array<Hash>] Array of hashes containing info about transport.
  #     Hash can contain _type_, _brand_, _model_, _number_ and _photo_.
  class Player < Encounter::Base
    include Encounter::HTMLParser

    attr_reader :uid

    lazy_attr_reader :name, :avatar, :points, :first_name, :patronymic_name,
                     :last_name, :country, :region, :city, :sex, :birthday,
                     :height, :weight, :email, :mobile_phone, :website, :skype,
                     :driver_license, :transport

    define_export_attrs :uid, :name, :avatar, :points, :first_name,
                        :patronymic_name, :last_name, :country, :region, :city,
                        :sex, :birthday, :height, :weight, :email, :website,
                        :mobile_phone, :skype, :driver_license, :transport

    define_parser_list :parse_avatar, :parse_birthday, :parse_attributes,
                       :parse_email, :parse_transport

    # @param [Encounter::Connection] conn
    # @param [Hash] params You can pass values in this parameters to predefine
    #   attributes. Any class attribute can be set.
    # @option params [Integer] :uid User ID. <b>Required option</b>
    #
    # @return [Encounter::Player] New object
    # @raise [ArgumentError] Raised if connection is not given
    # @raise [ArgumentError] Raised if :uid option is not defined
    def initialize(conn, params)
      raise ArgumentError, ':uid is needed' unless params.key? :uid

      super(conn, params)
    end

    # @private
    ID_PREFIX = 'EnTabContainer1_content_ctl00_panelLine'.freeze
    # @private
    ID_PREFIX_INF = "#{ID_PREFIX}PersonalData_personalDataBlock".freeze
    # @private
    ID_PREFIX_CON = "#{ID_PREFIX}Contacts_contactsBlock".freeze
    # @private
    ID_PREFIX_TRA = "#{ID_PREFIX}Transport_transportBlock".freeze
    # @private
    ID_PREFIX_LOC = "#{ID_PREFIX}Location_locationBlock".freeze

    # @private
    PARSER_OBJECTS = [
      {
        id: 'enUserDetailsPanel_lblPointsVal', attr: 'points',
        proc: proc { |r| r.tr(',', '.').to_f }
      },
      { id: "#{ID_PREFIX_INF}_lblFirstNameVal", attr: 'first_name' },
      { id: "#{ID_PREFIX_INF}_lblPatronymicNameVal", attr: 'patronymic_name' },
      { id: "#{ID_PREFIX_INF}_lblLastNameVal", attr: 'last_name' },
      {
        id: "#{ID_PREFIX_INF}_lblGenderTextVal", attr: 'sex',
        proc: proc { |r| r == 'Мужской' ? :male : :female }
      },
      {
        id: "#{ID_PREFIX_INF}_lblHeightVal", attr: 'height',
        proc: proc { |r| r.to_i }
      },
      {
        id: "#{ID_PREFIX_INF}_lblWeightVal", attr: 'weight',
        proc: proc { |r| r.to_i }
      },
      {
        id: "#{ID_PREFIX_TRA}_lblDrvLicenseVal", attr: 'driver_license',
        proc: proc { |r| r.scan(/[A-Z]/).map(&:to_sym) }
      },
      { id: "#{ID_PREFIX_CON}_lblMobilePhoneVal", attr: 'mobile_phone' },
      { id: "#{ID_PREFIX_CON}_SkypeValue", attr: 'skype' },
      { id: "#{ID_PREFIX_LOC}_CountryText", attr: 'country' },
      { id: "#{ID_PREFIX_LOC}_ProvinceText", attr: 'region' },
      { id: "#{ID_PREFIX_LOC}_CityText", attr: 'city' }
    ].freeze

    private

    def parse_avatar(obj)
      o = obj.css('#enUserDetailsPanel_lnkAvatarEdit img').first
      n = o.parent.parent.next_element.css('td span').first.text
      { avatar: o['src'], name: n }
    end

    def parse_birthday(obj)
      {
        birthday: %w[Date Year].map do |x|
                    id = "##{ID_PREFIX_INF}_lblBirth#{x}TextVal"
                    next if obj.css(id).empty?
                    obj.css(id).first.text
                  end.compact.join(' ')
      }
    end

    def parse_email(obj)
      idml = "##{ID_PREFIX_CON}_lblEmailVal noscript"
      idws = "##{ID_PREFIX_CON}_lWebSiteValue"
      {
        email: obj.css(idml).map(&:text).join,
        website: obj.css(idws).map { |r| r['href'] }.join
      }
    end

    def parse_car_field(obj, id, field)
      obj.css("#{id}_#{field}").map(&:text).join
    end

    def parse_car(obj, id)
      {
        type: parse_car_field(obj, id, 'TransportTypeText'),
        brand: parse_car_field(obj, id, 'CarMaker'),
        model: parse_car_field(obj, id, 'CarModel'),
        number: parse_car_field(obj, id, 'TransportNameText'),
        photo: obj.css("#{id}_TransportPhoto").map { |x| x['href'] }.join
      }
    end

    def parse_transport(obj)
      {
        transport: (1..15).map do |i|
          id = "##{ID_PREFIX_TRA}_TransportRepeater_ctl#{i.to_s.rjust(2, '0')}"
          next if obj.css("#{id}_TransportTypeText").empty?
          parse_car obj, id
        end.compact
      }
    end

    def load_data
      dom_page = Nokogiri::HTML(@conn.page_get('/UserDetails.aspx', uid: uid))

      raise 'No such player' unless dom_page.css('form#MainForm').empty?
      assign_values parse_all(dom_page.css('td#tdContentCenter').first)
    end
  end
end
