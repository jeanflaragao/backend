module Bookmakers
  class CreateService
    def self.call(user:, params:)
      new(user: user, params: params).call
    end

    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      bookmaker = nil

      ActiveRecord::Base.transaction do
        bookmaker = @user.bookmakers.create!(@params)
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
