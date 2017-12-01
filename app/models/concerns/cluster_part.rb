
module ClusterPart
  extend ActiveSupport::Concern

  include HasMaintenanceWindows
  include HasSupportType

  SUPPORT_TYPES = SupportType::VALUES + ['inherit']

  included do
    has_many :cases
    has_many :maintenance_windows

    validates :name, presence: true
    validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end
end
