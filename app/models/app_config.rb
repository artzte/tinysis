AppConfig = ConfigSpartan.create do
  file "#{Rails.root}/config/app_config.yml"
  file "#{Rails.root}/config/app_config/#{Rails.env}.yml"
end
