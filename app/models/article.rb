class Article < ApplicationRecord
  class << self
    def globally_available?
      true
    end
  end

  belongs_to :topic

  validates :title,
    presence: true,
    uniqueness: {
      scope: :topic,
    }
  validates :url, presence: true
  validates :meta, presence: true
end
