module Encounter
  # Class for player information
  class Player < Encounter::Base
    attr_reader :uid

    lazy_attr_reader :name

    define_export_attrs :uid, :name

    def initialize(conn, params)
      raise ':uid is needed' unless params.key? :uid

      super(conn, params)
    end
  end
end
