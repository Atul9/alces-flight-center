class AssetRecordFieldDefinition < ApplicationRecord
  include AdminConfig::AssetRecordFieldDefinition

  IDENTIFIER_ROOT = name.underscore.parameterize(separator: '_')

  SETTABLE_LEVELS = [
    # Settable at group-level; overridable at component-level.
    'group',

    # Settable at component-level only.
    'component',
  ].freeze

  has_and_belongs_to_many :component_types
  has_many :asset_record_fields

  validates :field_name, presence: true
  validates :level, inclusion: { in: SETTABLE_LEVELS }, presence: true

  validates :data_type,
            inclusion: { in: AssetRecordField::VALID_DATA_TYPES }

  class << self
    def all_identifiers
      all_identifiers_to_definitions.keys
    end

    def definition_for_identifier(identifier)
      all_identifiers_to_definitions[identifier]
    end

    def globally_available?
      true
    end

    private

    def all_identifiers_to_definitions
      @all_identifiers_to_definitions ||= all.map do |definition|
        [definition.identifier, definition]
      end.to_h
    end
  end

  def identifier
    "#{IDENTIFIER_ROOT}_#{id}".to_sym
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting level.
  def level_enum
    SETTABLE_LEVELS
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting data_type.
  def data_type_enum
    AssetRecordField::ValidDataTypes::VALID_DATA_TYPES
  end

  def settable_for_group?
    level == 'group'
  end

  #
  # The production database contains nil data_types atm
  # In the event of a nil, the data_type will default to short_text
  # and issue a deprecation warning
  #
  def data_type
    return super unless super.nil?
    ActiveSupport::Deprecation.warn <<-EOF.strip_heredoc
      #{self.class}:'#{field_name}' does not have a data_type set.
      Defaulting to 'short_text'
    EOF
    'short_text'
  end
end
