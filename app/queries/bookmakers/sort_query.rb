module Bookmakers
  class SortQuery
    SORTABLE_FIELDS = %i[name country created_at updated_at].freeze

    DEFAULT_SORT = { created_at: :desc }.freeze

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

      relation.order(sort => normalized_direction)
    end

    private

    def valid_sort?
      SORTABLE_FIELDS.include?(sort&.to_sym)
    end

    def normalized_direction
      direction == "asc" ? :asc : :desc
    end

    def default_order
      relation.order(created_at: :desc)
    end
  end
end
