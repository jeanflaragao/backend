class SortQuery
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
  
    relation.order(sort.to_sym => normalized_direction)
  end

  private

  def sortable_fields
    relation.klass::SORTABLE_FIELDS
  end

  def default_sort
    relation.klass::DEFAULT_SORT
  end

  def valid_sort?
    sortable_fields.include?(sort&.to_sym)
  end

  def normalized_direction
    direction == "asc" ? :asc : :desc
  end

  def default_order
    relation.order(default_sort)
  end
end