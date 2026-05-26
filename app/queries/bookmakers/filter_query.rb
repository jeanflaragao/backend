module Bookmakers
  class FilterQuery
    FILTERS = {
      status: Filters::StatusFilter,
      country: Filters::CountryFilter
    }.freeze

    attr_reader :relation, :filters

    def initialize(relation:, filters:)
      @relation = relation
      @filters = filters || {}
    end

    def self.call(...)
      new(...).call
    end

    def call
      FILTERS.reduce(relation) do |scope, (key, filter_class)|
        filter_class.new(relation: scope, value: filters[key]).call
      end
    end
  end
end
