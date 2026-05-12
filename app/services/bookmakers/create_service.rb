module Bookmakers
  class CreateService
    def self.call(params:)
      new(params:).call
    end

    def initialize(params:)
      @params = params
    end

    def call
      bookmaker = nil

      ActiveRecord::Base.transaction do
        bookmaker = Bookmaker.create!(@params)
      end

      success(bookmaker)
    rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages)
    end

    private

    def success(bookmaker)
      {
        success: true,
        bookmaker: bookmaker
      }
    end

    def failure(errors)
      {
        success: false,
        errors: errors
      }
    end
  end
end
