class Component < ApplicationRecord
  include HasSupportType

  SUPPORT_TYPES = SupportType::VALUES + ['inherit']

  belongs_to :component_group
  has_one :component_type, through: :component_group
  has_one :cluster, through: :component_group
  has_many :asset_record_fields

  validates_associated :component_group
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def case_form_json
    {
      id: id,
      name: name,
      supportType: support_type,
    }
  end

  def asset_record
    @asset_record ||= begin
      group_record_fields = extract_asset_record_fields(component_group)
      component_record_fields = extract_asset_record_fields(self)

      # Merge fields set at component-level over those set at group-level, so
      # those set at component-level take precedence.
      group_record_fields.merge(component_record_fields).values.map do |field|
        [field.name, field.value]
      end.to_h
    end
  end

  private

  def extract_asset_record_fields(model)
    model.asset_record_fields.map do |field|
      [field.id, field]
    end.to_h
  end
end
