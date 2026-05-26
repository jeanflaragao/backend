class Bookmaker < ApplicationRecord
  SEARCHABLE_FIELDS = %w[name country].freeze

  belongs_to :user

  validates :name, presence: true
  validates :name, uniqueness: true
end
