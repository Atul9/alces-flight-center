
class Case
  class AvailableSupportValidator < Validator
    def validate(record)
      @record = record

      validate_can_only_request_consultancy_support_for_advice_part
    end

    private

    delegate :associated_model, to: :record

    def validate_can_only_request_consultancy_support_for_advice_part
      # This rule does not apply to Cases for special Issues, which are created
      # via separate buttons outside of the standard Case form.
      return if record.issue.special?

      if associated_model&.advice? && record.tier_level < 3
        record.errors.add(associated_model_name, advice_part_error)
      end
    end

    def associated_model_name
      associated_model.readable_model_name
    end

    def advice_part_error
      "is #{SupportType::ADVICE_TEXT}, only consultancy support may be requested"
    end
  end
end
