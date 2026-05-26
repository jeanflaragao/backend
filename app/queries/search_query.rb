class SearchQuery
  attr_reader :relation, :search

  def initialize(relation:, search:)
    @relation = relation
    @search = search
  end

  def self.call(...)
    new(...).call
  end

  def call
    return relation if search.blank?

    searchable_fields = relation.klass::SEARCHABLE_FIELDS

    conditions =
      searchable_fields.map { |field| "#{field} ILIKE :search" }.join(" OR ")

    relation.where(conditions, search: "%#{search}%")
  end
end
