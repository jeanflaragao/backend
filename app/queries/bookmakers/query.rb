module Bookmakers
  class Query
    def self.call(scope:, filters:)
      new(scope: scope, filters: filters).call
    end

    def initialize(scope:, filters:)
      @scope = scope
      @filters = filters
    end

    def call
      filter_by_status
      filter_by_country
      filter_by_name

      scope.order(created_at: :desc)
    end

    private

    attr_reader :scope, :filters

    def filter_by_status
      return unless filters[:status].present?

      @scope = scope.where(status: filters[:status])
    end

    def filter_by_country
      return unless filters[:country].present?

      @scope = scope.where(country: filters[:country])
    end

    def filter_by_name
      return unless filters[:search].present?

      @scope = scope.where(
        "name ILIKE ?",
        "%#{filters[:search]}%"
      )
    end
  end
end
