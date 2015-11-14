class UserMailer < ActionMailer::Base

  def password_reset(user, password)
    # Email header info MUST be added here
    @subject    = AppConfig.app_domain + ' Password Reset'
    @recipients = user.email
    @from       = AppConfig.app_accounts_email

    # Email body substitutions go here
    @body["name"] = user.first_name
    @body["login"] = user.login
    @body["password"] = password
    @body["id"] = user.id
    @body["org"] = AppConfig.app_organization
    @body["domain"] = AppConfig.app_domain
    @body["name"] = user.first_name

    # Email body substitutions go here
    @sent_on    = Time.now.gmtime
    @headers    = {}
  end

  def status_reminder(sent_at = Time.now.gmtime)
    @subject    = 'UserMailer#status_reminder'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end

  def trouble_report(title, current_user, data_hash = {})
    @subject = "[#{AppConfig.app_domain}]: #{title}"
    @recipients = AppConfig.app_exception_email_recipient
    @from       = AppConfig.app_accounts_email
    @body["data"] = data_hash
    @body["user"] = current_user
  end

end
