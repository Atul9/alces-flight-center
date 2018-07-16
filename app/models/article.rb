class Article < ApplicationRecord
  belongs_to :topic
  delegate :site, to: :topic

  validates :title,
    presence: true,
    uniqueness: {
      scope: :topic,
    }
  validates :url, presence: true
  validates :meta, presence: true

  private

  def permissions_check_unneeded?
    topic.global? || super
  end
end
