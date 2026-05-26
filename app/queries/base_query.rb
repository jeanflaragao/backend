class BaseQuery
  attr_reader :relation,
              :filters,
              :search,
              :sort,
              :direction,
              :filter_class,
              :sort_class

  def initialize(
    relation:,
    filters:,
    sort:,
    search:,
    direction:,
    filter_class:,
    sort_class:
  )
    @relation = relation
    @filters = filters
    @search = search
    @sort = sort
    @direction = direction
    @filter_class = filter_class
    @sort_class = sort_class
  end

  def self.call(...)
    new(...).call
  end

  def call
    filtered_relation = filter_class.call(relation: relation, filters: filters)

    searched_relation =
      SearchQuery.call(relation: filtered_relation, search: search)

    sort_class.call(
      relation: searched_relation,
      sort: sort,
      direction: direction
    )
  end
end
