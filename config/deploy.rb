set :environment, ENV["env"]||"development"

set :application, "novatiny"
set :domain,      "69.25.136.54"
set :repository, 'git://github.com/artzte/tinysis.git'
set :deploy_to, "/home/deploy/#{environment}"
set :config_files, ['database.yml']
set :web_command, "sudo apachectl"
set :config_path, "/home/deploy/config/#{environment}"
set :skip_scm, false

task :remote_path do
  puts remote_path
end

remote_task :symlink do
  # shared between deploys
  run "if [[ ! -d \"#{shared_path}/assets/gradesheet\" ]]; then mkdir -p \"#{shared_path}/assets/gradesheet\"; fi"
  run "if [[ ! -d \"#{release_path}/public/assets\" ]]; then mkdir -p \"#{release_path}/public/assets\"; fi"
  run "ln -s #{shared_path}/assets/gradesheet #{release_path}/public/assets/gradesheet"

  # config files
  run "ln -s #{config_path}/database.yml                    #{release_path}/config/database.yml"
  run "ln -s #{config_path}/environments/#{environment}.yml #{release_path}/config/app_config/#{environment}.yml"
  run "ln -s #{config_path}/environments/#{environment}.rb  #{release_path}/config/environments/#{environment}.rb"

  # bundle folder
  run "if [[ ! -d \"#{shared_path}/bundle\" ]]; then mkdir -p \"#{shared_path}/bundle\"; fi"
  run "ln -s #{shared_path}/bundle  #{release_path}/vendor/bundle"
end

remote_task :bundle do
  run "cd #{release_path} && env bundle install --deployment --binstubs"
end

remote_task :generate_css do
  run "cd #{release_path} && env RAILS_ENV=#{environment} bundle exec compass compile"
end

remote_task :package_assets do
  run "cd #{release_path} && env RAILS_ENV=#{environment} bundle exec rake assets:package"
end

desc "Full deployment cycle"
task "vlad:deploy" => %w[
  vlad:update
  symlink
  bundle
  generate_css
  package_assets
  vlad:start_app
]
