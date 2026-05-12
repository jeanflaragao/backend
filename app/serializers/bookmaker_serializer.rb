class BookmakerSerializer
  include Alba::Resource

  attributes :id,
             :name,
             :website,
             :country,
             :status

  attribute :homepage  do |bookmaker|
    bookmaker.website
  end
end
