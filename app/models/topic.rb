class Topic < ApplicationRecord
  VALID_SCOPES = [
    'global',
    'site',
  ].freeze

  belongs_to :site, required: false
  has_many :articles

  validates :title, presence: true
  validates :scope,
    presence: true,
    inclusion: { within: ['global'] },
    if: ->() { site.nil? }
  validates :scope,
    presence: true,
    inclusion: { within: ['site'] },
    if: ->() { site.present? }

  def global?
    scope == 'global'
  end

  private

  def permissions_check_unneeded?
    global? || super
  end
end
