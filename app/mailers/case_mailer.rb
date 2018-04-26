class CaseMailer < ApplicationMailer

  layout 'case_mailer'

  default bcc: Rails.application.config.email_bcc_address

  def new_case(my_case)
    @case = my_case
    mail(
      cc: @case.email_recipients.reject { |contact| contact == @case.user.email }, # Exclude the user raising the case
      subject: @case.email_subject
    )
  end

  def change_assignee(my_case, previous_assignee)
    @case = my_case
    @previous = previous_assignee
    mail(
      cc: (@case.email_recipients + [@case.assignee&.email]).uniq, # Send to all including new assignee
      subject: @case.email_subject
    )
  end

  def comment(comment)
    @comment = comment
    @case = @comment.case
    mail(
      cc: @case.email_recipients.reject { |contact| contact == @comment.user.email }, # Exclude the user making the comment
      subject: @case.email_reply_subject,
    )
  end

  def maintenance(my_case, text)
    @case = my_case
    @text = text
    mail(
      cc: @case.email_recipients,
      subject: @case.email_reply_subject
    )
  end
end
