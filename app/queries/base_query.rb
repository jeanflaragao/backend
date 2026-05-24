module Queries
  class BaseQuery
    attr_reader(:relation, :filters, :sort, :direction, :filter_class)

    def initialize(relation:, filters:, sort:, direction:, filter_class:)
      @relation = relation
      @filters = filters
      @sort = sort
      @direction = direction
      @filter_class = filter_class
    end

    def self.call(...)
      new(...).call
    end

    def call
      filtered_relation =
        filter_class.call(relation: relation, filters: filters)

      SortQuery.call(
        relation: filtered_relation,
        sort: sort,
        direction: direction
      )
    end
  end
end
