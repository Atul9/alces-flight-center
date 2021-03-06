
class ServiceType < ApplicationRecord
  include AdminConfig::ServiceType

  has_many :services
  has_many :issues

  validates :name, presence: true

  scope :automatic, -> { where(automatic: true) }

  def self.globally_available?
    true
  end
end
