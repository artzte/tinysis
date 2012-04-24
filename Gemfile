source :gemcutter
gem "rails", "~> 2.3.14"

gem "compass"
gem "haml"
gem "sass"
gem "fastercsv"
gem "mysql"
gem "vlad"
gem "vlad-git"
gem "RedCloth"
gem "rmagick"
gem "app_config", :path => "vendor/gems/app_config-1.2.0"
gem 'jammit'

# bundler requires these gems in all environments
# gem "nokogiri", "1.4.2"
# gem "geokit"
#
#
#
group :production do
  gem "passenger"
end

group :development do
  # bundler requires these gems in development
  gem "ruby-debug19"
  gem "vlad", :require => false
  gem "vlad-git", :require => false

end

group :test do
  # bundler requires these gems while running tests
  # gem "rspec"
  # gem "faker"
end
