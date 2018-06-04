module ClustersHelper

  def credit_value_class(value)
    if value.negative? || value.zero?
      'text-danger'
    else
      'text-success'
    end
  end

  def quarter_display_name(start)
    "Q#{((start.month - 1) / 3) + 1} (#{start.strftime('%d %b')} - #{start.end_of_quarter.strftime('%d %b')}) #{start.year}"
  end

end
