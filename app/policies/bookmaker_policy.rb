class BookmakerPolicy
  attr_reader :user, :bookmaker

  def initialize(user, bookmaker)
    @user = user
    @bookmaker = bookmaker
  end

  def show?
    bookmaker.user_id == user.id
  end
end
