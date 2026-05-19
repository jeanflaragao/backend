module Bookmakers
  module Filters
    class SearchFilter < BaseFilter
      def call
        return relation if value.blank?

        relation.where("name ILIKE ?", "%#{value}%")
      end
    end
  end
end
