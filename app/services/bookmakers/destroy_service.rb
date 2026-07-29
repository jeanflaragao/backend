module Bookmakers
  class DestroyService
    def self.call(bookmaker:)
      new(bookmaker).call
    end

    def initialize(bookmaker)
      @bookmaker = bookmaker
    end

    def call
      bookmaker.destroy!
    end

    private

    attr_reader :bookmaker
  end
end
