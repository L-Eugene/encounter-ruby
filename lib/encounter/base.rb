module Encounter
  # Basic class for Encounter objects.
  # Implements lazy-load attribute definition.
  #
  # @abstract
  class Base
    # Defines attribute reader with lazy load function.
    # {#load_data} method is called if this attribute value is requested
    # while it was not defined.
    #
    # @param [Array<Symbol>] var_names Parameter names
    def self.lazy_attr_reader(*var_names)
      var_names.each do |var_name|
        define_method(var_name) do
          load_data unless instance_variable_defined? "@#{var_name}"
          instance_variable_get "@#{var_name}"
        end
      end
    end

    # Defines attribute accessor with lazy load function.
    # {#load_data} method is called if this attribute value is requested
    # while it was not defined.
    #
    # @param [Array<Symbol>] var_names Parameter names
    def self.lazy_attr_accessor(*var_names)
      var_names.each do |var_name|
        lazy_attr_reader var_name
        attr_writer var_name
      end
    end

    # Defining list of export attributes. This attributes will
    # be returned by {#to_json} and {#to_hash} methods.
    #
    # @param [Array<Symbol>] items List of attributet names.
    def self.define_export_attrs(*items)
      list = []
      items.each do |item|
        raise ArgumentError, 'Want symbol parameters' unless item.is_a? Symbol
        list << item
      end
      define_method(:export_fields) do
        list.freeze
      end
    end

    define_export_attrs

    # @param [Encounter::Connection] conn
    # @param [Hash] params You can pass values in this parameters to predefine
    #   attributes. Any class attribute can be set.
    def initialize(conn, params)
      raise 'Connection needed' unless conn.is_a? Encounter::Connection
      raise 'Only hash parameter accepted' unless params.is_a? Hash

      @conn = conn

      assign_values(params)
    end

    # Exports attributes, listed in {.define_export_attrs} as JSON string.
    #
    # @return [String]
    def to_json(options = nil)
      to_hash.to_json(options)
    end

    # Exports attributes, listed in {.define_export_attrs} as Hash.
    #
    # @return [Hash]
    def to_hash
      Hash[export_fields.map { |f| [f, send(f)] }]
    end

    # This method should be defined in subclasses and load all data
    # needed to parse data.
    # @abstract
    def load_data
      raise NotImplementedError, 'Should be defined in subclass'
    end

    private

    def assign_values(hash)
      raise ArgumentError, 'Parameter must be hash.' unless hash.is_a? Hash

      hash.each do |p, v|
        raise ArgumentError, "Wrong attribute: #{p}" unless respond_to? p
        instance_variable_set("@#{p}", v)
      end
    end
  end
end
