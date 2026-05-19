module Bookmakers
  class SortQuery
    SORT_FIELDS = %w[created_at name country status].freeze

    DIRECTIONS = %w[asc desc].freeze

    attr_reader :relation, :sort, :direction

    def initialize(relation:, sort:, direction:)
      @relation = relation
      @sort = sort
      @direction = direction
    end

    def self.call(...)
      new(...).call
    end

    def call
      return default_order unless valid_sort?

      relation.order(sort => direction)
    end

    private

    def valid_sort?
      SORT_FIELDS.include?(sort.to_s) && DIRECTIONS.include?(direction.to_s)
    end

    def default_order
      relation.order(created_at: :desc)
    end
  end
end
