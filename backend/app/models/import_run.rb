class ImportRun < ApplicationRecord
  has_many :ingredient_parse_errors, dependent: :delete_all

  STATUSES = %w[running completed failed].freeze

  validates :source_url, :parser_version, :status, :started_at, presence: true
  validates :status, inclusion: { in: STATUSES }
end
