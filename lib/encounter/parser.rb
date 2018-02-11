module Encounter
  # parser for html pages
  module HTMLParser
    def self.included(base)
      base.extend Encounter::ParserClassMethods
    end

    # Running all methods from {.define_parser_list}
    #
    # @param object [Nokogiri::CSS::Node] Nokigiri object
    #
    # @return [Hash]
    def parse_all(object)
      return {} unless respond_to? :parser_list
      raise 'parser_list must be Array' unless parser_list.is_a? Array

      result = {}
      parser_list.each do |k|
        raise "Unknown method #{k}" unless respond_to? k, true
        result.merge! send(k, object)
      end
      result
    end

    def parse_attributes(obj)
      Hash[
        self.class::PARSER_OBJECTS.map do |o|
          res = obj.css("#{o[:id]}").map(&:text).join
          res = o[:proc].call(res) if o[:proc]
          [o[:attr], res]
        end
      ]
    end
  end

  # class method for parser
  module ParserClassMethods
    def define_parser_list(*items)
      list = []
      items.each do |item|
        raise ArgumentError, 'Want symbol parameters' unless item.is_a? Symbol
        list << item
      end
      define_method(:parser_list) do
        list.freeze
      end
    end
  end
end
