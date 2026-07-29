module Bookmakers
  class ActiveAccountsExistError < ApplicationError
    def initialize
      super(
        code: "active_accounts_exist",
        message: "Cannot delete bookmaker with active accounts."
      )
    end
  end
end
