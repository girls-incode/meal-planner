class User < ApplicationRecord
  has_many :pantry_items, dependent: :nullify

  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true
end
