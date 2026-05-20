module Bookmakers
  class Query
    attr_reader :relation, :filters, :sort, :direction

    def initialize(relation:, filters:, sort:, direction:)
      @relation = relation
      @filters = filters
      @sort = sort
      @direction = direction
    end

    def self.call(...)
      new(...).call
    end

    def call
      filtered_relation = FilterQuery.call(relation: relation, filters: filters)

      SortQuery.call(
        relation: filtered_relation,
        sort: sort,
        direction: direction
      )
    end
  end
end
