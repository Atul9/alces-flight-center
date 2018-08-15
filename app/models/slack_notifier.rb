require 'slack-notifier'
class SlackNotifier
  class << self
    include Rails.application.routes.url_helpers

    delegate :slack_webhook_url,
      :slack_channel,
      :slack_username,
      to: 'Rails.application.config'

    def case_notification(kase)
      notification_text = "New case created on #{kase.cluster.name}"

      case_url = cluster_case_url(kase.cluster, kase)

      notification_details = [
          "*Tier #{kase.tier_level}*",
          *format_fields(kase.email_properties, case_url)
      ].join("\n")

      case_note = {
        fallback: notification_text,
        color: "#18bc9c",
        pretext: notification_text,
        author_name: kase.user.name,
        title: subject_and_id_title(kase),
        title_link: case_url,
        text: notification_details,
        mrkdwn: false
      }

      send_notification(case_note)
    end

    def assignee_notification(kase, assignee)
      notification_text = if assignee
                            "#{assignee.name} has been assigned to #{kase.display_id}"
                          else
                            "#{kase.display_id} is no longer assigned"
                          end
      assignee_note = {
        fallback: notification_text,
        color: "#6e5494",
        title: subject_and_id_title(kase),
        title_link: cluster_case_url(kase.cluster, kase),
        fields: [
          {
            title: "Assigned to",
            value: assignee&.name || 'Nobody',
            short: true
          }
        ]
      }

      send_notification(assignee_note)
    end

    def comment_notification(kase, comment)
      notification_text = "New comment from #{comment.user.name} on #{kase.display_id}"
      comment_note = {
        fallback: notification_text,
        color: "#2794d8",
        author_name: comment.user.name,
        title: subject_and_id_title(kase),
        title_link: cluster_case_url(kase.cluster, kase),
        fields: [
          {
            title: "New comment",
            value: comment.text,
            short: false
          }
        ]
      }

      send_notification(comment_note)
    end

    def maintenance_state_transition_notification(kase, text)
      maintenance_notification(kase, text, "#000000")
    end

    def maintenance_ending_soon_notification(kase, text)
      maintenance_notification(kase, text, 'warning')
    end

    def log_notification(log)
      notification_text = "New log created on #{log.cluster.name}" \
        " #{log&.component ? 'for ' + log.component.name : nil }"

      logs_url = cluster_logs_url(log.cluster)

      log_note = {
        fallback: notification_text,
        color: "#8daec2",
        pretext: notification_text,
        author_name: log.engineer.name,
        title: "Details",
        title_link: logs_url,
        text: restrict_text_length(log.details, logs_url),
        mrkdwn: true
      }

      send_notification(log_note)
    end

    def change_request_notification(kase, text, user)
      text = "A change request for this case #{text}"
      change_request_note = {
        fallback: text,
        color: '#f44192',
        author_name: user.name,
        title: subject_and_id_title(kase),
        title_link: cluster_case_url(kase.cluster, kase),
        text: "*<#{cluster_case_change_request_url(kase.cluster, kase)}|Change Request Event>*\n#{text}",
      }

      send_notification(change_request_note)
    end

    def case_association_notification(kase, user)

      reference_texts = kase.associations
                            .map { |a| a.decorate.reference_text }

      text = %{Changed the affected components on this case to:

• #{reference_texts.join("\n • ")}
}

      send_notification(
        author_name: user.name,
        title: subject_and_id_title(kase),
        title_link: cluster_case_url(kase.cluster, kase),
        text: text
      )
    end

    private

    def maintenance_notification(kase, text, colour)
      maintenance_note = {
        fallback: text,
        color: colour,
        title: subject_and_id_title(kase),
        title_link: cluster_case_url(kase.cluster, kase),
        fields: [
          {
            title: "Maintenance Info",
            value: text,
            short: false
          }
        ]
      }

      send_notification(maintenance_note)
    end

    def send_notification(note)
      return unless slack_webhook_url
      notifier.ping channel: slack_channel,
        username: slack_username,
        attachments: note
    end

    def notifier
      Slack::Notifier.new slack_webhook_url
    end

    def restrict_text_length(text, url)
      text.length > 80 ? text[0, 80] + "<#{url}|...>" : text
    end

    def subject_and_id_title(kase)
      "[#{kase.display_id}] #{kase.subject}"
    end

    def format_fields(hash, url)
      hash.map do |key, value|
        if value.is_a?(Hash)
          format_fields(value, url)
        else
          "*#{key}*\n#{restrict_text_length(value, url)}"
        end
      end.flatten
    end
  end
end
