
class Log < ApplicationRecord
  include MarkdownColumn(:details)
  include AdminConfig::Log

  default_scope { order(created_at: :desc) }

  belongs_to :cluster
  belongs_to :component, optional: true
  has_one :site, through: :cluster
  belongs_to :engineer, class_name: 'User', foreign_key: 'user_id'
  has_and_belongs_to_many :cases

  validates :details, presence: true
  validate :engineer_is_a_admin
  validate :cases_belong_to_cluster
  validate :component_belongs_to_cluster

  after_initialize :assign_cluster_if_necessary

  private

  def engineer_is_a_admin
    unless engineer&.admin?
      errors.add(:engineer, 'must be an admin')
    end
  end

  def cases_belong_to_cluster
    cases.each do |kase|
      unless kase.cluster == cluster
        msg = "case #{kase.display_id} is for a different cluster"
        errors.add(:cases, msg)
      end
    end
  end

  COMPONENT_CLUSTER_ERROR = 'must be in the same cluster as the log'
  def component_belongs_to_cluster
    return if component.nil?
    correct_cluster = (component.cluster == cluster)
    errors.add :component, COMPONENT_CLUSTER_ERROR unless correct_cluster
  end

  def assign_cluster_if_necessary
    return if cluster
    self.cluster = component.cluster if component
  end
end

