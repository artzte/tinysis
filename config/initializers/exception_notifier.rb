ExceptionNotification::Notifier.exception_recipients = [AppConfig.app_exception_email_recipient]
ExceptionNotification::Notifier.sender_address = "\"#{AppConfig.app_domain} Exception Mailer\" <#{AppConfig.app_admin_email}>"
ExceptionNotification::Notifier.email_prefix = "[TinySIS glitch] "
