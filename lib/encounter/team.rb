require 'encounter/base'

module Encounter
  # Team class
  class Team < Encounter::Base
    include Encounter::HTMLParser

    attr_reader :tid

    lazy_attr_reader :name

    define_export_attrs :tid, :name

    def initialize(conn, params)
      raise ':tid is needed' unless params.key? :tid

      super(conn, params)
    end
  end
end
