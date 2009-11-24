class UserMailer < ActionMailer::Base

  def password_reset(user, password)
		# Email header info MUST be added here
    @subject    = APP_DOMAIN + ' Password Reset'
    @recipients = user.email
    @from       = APP_ACCOUNT_EMAIL
		
		# Email body substitutions go here
		@body["name"] = user.first_name
		@body["login"] = user.login
		@body["password"] = password
		@body["id"] = user.id
		@body["org"] = APP_ORGANIZATION
		@body["domain"] = APP_DOMAIN
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
	
	
end
