module Bookmakers
  module Filters
    class BaseFilter
      attr_reader :relation, :value

      def initialize(relation:, value:)
        @relation = relation
        @value = value
      end

      def call
        raise NotImplementedError
      end
    end
  end
end
