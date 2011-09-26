require 'app_config'
::AppConfig = ApplicationConfiguration.new(RAILS_ROOT+"/config/app_config.yml",
                                           RAILS_ROOT+"/config/app_config/#{RAILS_ENV}.yml",
                                           RAILS_ROOT+"/config/app_config/local.yml")
