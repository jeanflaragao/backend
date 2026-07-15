class BookmakerSerializer
  include Alba::Resource

  attributes :id,
             :name,
             :country,
             :status

  attribute :homepage  do |bookmaker|
    bookmaker.website
  end
end
