module ApplicationHelper
  def icon(name, interactive: false, inline: false, **args)
    classes = [
      (inline ? 'inline-icon' : 'fa-2x'),
      (interactive ? 'interactive-icon' : 'icon'),
      args.delete(:class)
    ].join(' ')

    fa_icon name, class: classes, **args
  end

  def boolean_symbol(condition)
    raw(condition ? '&check;' : '&cross;')
  end

  def new_case_form(clusters:, single_part: nil)
    clusters_json = json_map(clusters.map(&:decorate), :case_form_json)
    raw(
      <<~EOF
        <div
          id='new-case-form'
          data-clusters='#{clusters_json}'
          #{single_part_data_attr(single_part)}
        ></div>
      EOF
    )
  end

  def scope_nav_link_procs
    @scope_nav_link_procs ||= ScopeNavLinksBuilder.new(scope: @scope).build
  end

  def icon_span(text, icon = '')
    raw("<span class='fa #{icon}'></span> ") + text
  end

  def dark_button_classes
    ['btn', 'btn-primary', 'btn-block']
  end

  def timestamp_td(description:, timestamp:)
    raw(
      <<~EOF.strip_heredoc
        <td
          title="#{description} on #{timestamp.to_formatted_s(:long)}"
          style="white-space: nowrap;"
        >
          #{timestamp.to_formatted_s(:short)}
        </td>
      EOF
    )
  end

  private

  # Map function with given name over enumerable collection of objects, then
  # turn result into JSON; useful when want to transform collection before
  # turning into JSON.
  def json_map(enumerable, to_json_function)
    enumerable.map(&to_json_function).reject(&:nil?).to_json
  end


  def single_part_data_attr(single_part)
    return unless single_part

    single_part_json ={
      id: @single_part.id,
      type: @single_part.class.to_s.downcase
    }.to_json

    "data-single-part=#{single_part_json}"
  end
end
