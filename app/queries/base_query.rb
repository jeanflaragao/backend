class BaseQuery
  attr_reader :relation,
              :filters,
              :search,
              :sort,
              :direction,
              :filter_class

  def initialize(
    relation:,
    filters:,
    sort:,
    search:,
    direction:,
    filter_class:
  )
    @relation = relation
    @filters = filters
    @search = search
    @sort = sort
    @direction = direction
    @filter_class = filter_class
  end

  def self.call(...)
    new(...).call
  end

  def call
    relation
      .then { filter_class.call(relation: _1, filters: filters) }
      .then { SearchQuery.call(relation: _1, search: search) }
      .then { SortQuery.call(relation: _1, sort: sort, direction: direction) }
  end
end
