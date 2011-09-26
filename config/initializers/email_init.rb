ActionMailer::Base.smtp_settings = {
  :enable_starttls_auto => true,
  :address => AppConfig.smtp_tls_config.address,
  :port => AppConfig.smtp_tls_config.port,
  :domain => AppConfig.smtp_tls_config._domain,
  :authentication => :plain,
  :user_name => AppConfig.smtp_tls_config.user_name,
  :password => AppConfig.smtp_tls_config.password
}
