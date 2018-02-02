
class AssetRecordFieldDefinitionDecorator < ApplicationDecorator
  def form_input(value, **options)
    case object.data_type
    when 'long_text'
      text_area(value, options)
    else
      text_field(value, options)
    end
  end

  private

  def text_area(value, options)
    options[:style] = "#{options[:style]} height:100px"
    h.text_area_tag(object.id, value, **options)
  end

  def text_field(value, options)
    h.text_field_tag(object.id, value, **options)
  end
end
