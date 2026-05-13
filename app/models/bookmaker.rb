class Bookmaker < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :name, uniqueness: true
end
