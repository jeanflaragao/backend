module Bookmakers
  module Filters
    class StatusFilter < BaseFilter
      def call
        return relation if value.blank?

        relation.where(status: value)
      end
    end
  end
end
