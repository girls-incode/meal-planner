class Pantry < ApplicationRecord
  SESSION_TOKEN_FORMAT = /\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/i.freeze

  has_many :pantry_items, dependent: :destroy
  has_many :ingredients, through: :pantry_items

  validates :session_token, presence: true, uniqueness: true

  before_validation { self.session_token ||= SecureRandom.uuid }
end
