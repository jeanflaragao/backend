class Bookmaker < ApplicationRecord
  SEARCHABLE_FIELDS = %w[name country].freeze
  SORTABLE_FIELDS = %i[
    name
    country
    created_at
    updated_at
  ].freeze
  
  DEFAULT_SORT = {
    created_at: :desc
  }.freeze
  
  belongs_to :user

  validates :name, presence: true
  validates :name, uniqueness: true
end
