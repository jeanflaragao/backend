module Bookmakers
  class FilterQuery
    FILTERABLE_FIELDS = %i[
      status
      country
    ].freeze

    attr_reader :relation, :filters

    def initialize(relation:, filters:)
      @relation = relation
      @filters = filters || {}
    end

    def self.call(...)
      new(...).call
    end

    def call
      FILTERABLE_FIELDS.reduce(relation) do |scope, field|
        value = filters[field]

        value.present? ? scope.where(field => value) : scope
      end
    end
  end
end