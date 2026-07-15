class BookmakerPolicy < ApplicationPolicy
  attr_reader :user, :bookmaker

  def initialize(user, bookmaker)
    @user = user
    @bookmaker = bookmaker
  end

  def show?
    owns_record?
  end

  def update?
    owns_record?
  end

  def destroy?
    owns_record?
  end
  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  private

  def owns_record?
    bookmaker.user_id == user.id
  end
end
