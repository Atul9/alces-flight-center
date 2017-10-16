class Site < ApplicationRecord
  include AdminConfig
  include MarkdownDescription

  has_many :users, dependent: :destroy
  has_many :additional_contacts, dependent: :destroy
  has_many :clusters, dependent: :destroy
  has_many :cases, through: :clusters
  has_many :components, through: :clusters

  validates :name, presence: true
  validates :canonical_name, presence: true

  before_validation CanonicalNameCreator.new, on: :create
end
