
class Case::Validator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    validate_correct_component_relationship
    validate_issue_allowed_for_cluster_or_component
  end

  private

  def validate_correct_component_relationship
    if record.issue.requires_component
      if !record.component
        record.errors.add(:component, 'issue requires a component but one was not given')
      elsif record.component.cluster != record.cluster
        record.errors.add(:component, 'given component is not part of given cluster')
      end
    elsif record.component
      record.errors.add(:component, 'issue does not require a component but one was given')
    end
  end

  def validate_issue_allowed_for_cluster_or_component
    {
      managed_issue_for_advice_component_error => managed_issue_for_advice_component?,
      managed_issue_for_advice_cluster_error => managed_issue_for_advice_cluster?,
      advice_only_issue_for_managed_component_error => advice_only_issue_for_managed_component?,
      advice_only_issue_for_managed_cluster_error => advice_only_issue_for_managed_cluster?,
    }.select { |_error, condition| condition }
      .map do |error, _condition|
      record.errors.add(:issue, error)
    end
  end

  def managed_issue_for_advice_cluster?
    record.issue.managed? &&
      !record.issue.requires_component &&
      record.cluster&.advice?
  end

  def managed_issue_for_advice_cluster_error
    managed_issue_error_for('cluster')
  end

  def managed_issue_for_advice_component?
    record.issue.managed? &&
      record.issue.requires_component &&
      record.component&.advice?
  end

  def managed_issue_for_advice_component_error
    managed_issue_error_for('component')
  end

  def managed_issue_error_for(model_type)
    <<-EOF.squish
      is only available for #{SupportType::MANAGED_TEXT}
      #{model_type.pluralize}, but given #{model_type} is
      #{SupportType::ADVICE_TEXT}
    EOF
  end

  def advice_only_issue_for_managed_component?
    record.issue.advice_only? &&
      record.issue.requires_component &&
      record.component.managed?
  end

  def advice_only_issue_for_managed_component_error
    advice_only_issue_error_for('component')
  end

  def advice_only_issue_for_managed_cluster?
    record.issue.advice_only? &&
      !record.issue.requires_component &&
      record.cluster.managed?
  end

  def advice_only_issue_for_managed_cluster_error
    advice_only_issue_error_for('cluster')
  end

  def advice_only_issue_error_for(model_type)
    <<-EOF.squish
      is only available for #{SupportType::ADVICE_TEXT}
      #{model_type.pluralize}, but given #{model_type} is
      #{SupportType::MANAGED_TEXT}
    EOF
  end
end