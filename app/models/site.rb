class Site < ApplicationRecord
  has_many :contacts, dependent: :destroy
  has_many :clusters, dependent: :destroy
  has_many :cases, through: :clusters
  has_many :components, through: :clusters
  validates :name, presence: true
end
