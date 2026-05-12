class BookmakerSerializer
  include Alba::Resource

  attributes :id,
             :name,
             :website,
             :country,
             :status
end
