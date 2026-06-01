module Bookmakers
  class IndexQuery
    attr_reader :relation, :params

    def initialize(relation:, params:)
      @relation = relation
      @params = params
    end

    def self.call(...)
      new(...).call
    end

    def call
      relation
        .then { filter(_1) }
        .then { search(_1) }
        .then { sort(_1) }
    end

    private

    def filter(scope)
      FilterQuery.call(
        relation: scope,
        filters: params
      )
    end

    def search(scope)
      SearchQuery.call(
        relation: scope,
        search: params[:search]
      )
    end

    def sort(scope)
      SortQuery.call(
        relation: scope,
        sort: params[:sort],
        direction: params[:direction]
      )
    end
  end
end