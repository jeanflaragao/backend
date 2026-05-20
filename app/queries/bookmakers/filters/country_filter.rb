module Bookmakers
  module Filters
    class CountryFilter < BaseFilter
      def call
        return relation if value.blank?

        relation.where(country: value)
      end
    end
  end
end
