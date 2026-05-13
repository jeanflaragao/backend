class User < ApplicationRecord
  has_many :bookmakers, dependent: :destroy

  validates :email,
            presence: true,
            uniqueness: true
end
