module ClustersHelper

  def credit_value_class(value)
    if value.negative?
      'text-warning'
    elsif value.zero?
      'text-muted'
    else
      'text-success'
    end
  end

  def quarter_display_name(start)
    "#{start.year} Q#{((start.month - 1) / 3) + 1} (#{start.strftime('%d %b')} - #{start.end_of_quarter.strftime('%d %b')})"
  end

end
