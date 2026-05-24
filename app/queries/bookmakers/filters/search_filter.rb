module Bookmakers
  module Filters
    class SearchFilter < BaseFilter
      def call
        return relation if value.blank?

        relation.where(
          "name ILIKE :query OR website ILIKE :query",
          query: "%#{value}%"
        )
      end
    end
  end
end
