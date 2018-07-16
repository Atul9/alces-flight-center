class Topic < ApplicationRecord
  class << self
    def globally_available?
      true
    end
  end

  has_many :articles

  validates :title, presence: true
end
