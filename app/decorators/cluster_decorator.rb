class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :components
  decorates_association :component_groups
  decorates_association :services

  def path
    h.cluster_path(self)
  end

  def links
    h.link_to name, path
  end

  def tabs
    [
      tabs_builder.overview,
      documents.empty? ? nil : { id: :documents, path: h.cluster_documents_path(self) },
      { id: :credit_usage, path: h.cluster_credit_usage_path(self) },
      { id: :checks, path: h.cluster_checks_path(self) },
      tabs_builder.logs,
      tabs_builder.cases,
      tabs_builder.maintenance,
      { id: :services, path: h.cluster_services_path(self) },
      {
        id: :components,
        dropdown: self.available_component_group_types.map do |t|
          {
            text: t.pluralize,
            path: h.cluster_components_path(self, type: t)
          }
        end.push(text: 'All', path: h.cluster_components_path(self))
      },
      notes_tab,
    ].compact
  end

  def case_form_json
    {
      id: id,
      name: name,
      components: components.map(&:case_form_json),
      services: services.map(&:case_form_json),
      supportType: support_type,
      chargingInfo: charging_info,
      # Encode MOTD in two forms: the raw form, to be used as the initial value
      # to be edited in the MOTD tool, and as sanitized, formatted HTML so the
      # current value can be displayed as it will be on the Cluster and in the
      # rest of Flight Center.
      motd: motd,
      motdHtml: h.simple_format(motd),
    }
  end

  def credit_balance_class
    if credit_balance.negative? || credit_balance.zero?
      'text-danger'
    elsif credit_balance < 10
      'text-warning'
    else
      'text-success'
    end
  end

  # List the first day of each quarter since this cluster was created, including
  # the current quarter (as defined by `Date.today`).
  def all_quarter_start_dates
    first_quarter = model.created_at.beginning_of_quarter
    last_quarter =  Date.today.beginning_of_quarter.to_datetime

    [].tap do |qs|
      curr_quarter = last_quarter
      while curr_quarter >= first_quarter
        qs << curr_quarter
        curr_quarter -= 3.months
      end
    end
  end

  def fa_icon
    'fa-server'
  end

  def type_name
    'Entire cluster'
  end

  def check_results_by_date(date)
    check_results.where(date: date).order(:cluster_check_id)
  end

  def last_checked
    if check_results.empty?
      'N/A'
    else
      check_results.order(date: :desc).first.date
    end
  end

  def no_of_checks_passed(date = last_checked)
    check_results.where(date: date).where.not(result: 'Failure').count
  end

  def check_groups(checks)
    checks.group_by do |c|
      if c.is_a? ClusterCheck
        c.check.check_category
      else
        c.cluster_check.check.check_category
      end
    end
  end

  def check_results_class
    if no_of_checks_passed.zero?
      'text-danger'
    elsif no_of_checks_passed < checks.count
      'text-warning'
    else
      'text-success'
    end
  end

  private

  def notes_tab
    if current_user.admin?
      {
        id: :notes,
        dropdown: [
          {
            text: 'Engineering',
            path: h.cluster_note_path(self, flavour: :engineering),
          },
          {
            text: 'Customer',
            path: h.cluster_note_path(self, flavour: :customer),
          },
        ]
      }
    else
      {
        id: :notes,
        path: h.cluster_note_path(self, flavour: :customer),
      }
    end
  end
end
