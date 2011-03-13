set :environment, ENV["env"]||"development"

set :application, "novatiny"
set :domain,      "74.63.3.51"
set :repository, 'git://github.com/artzte/tinysis.git'
set :deploy_to, "/var/apps/novatiny/#{environment}"
set :config_files, ['database.yml']
set :web_command, "sudo apachectl"
set :config_path, "/var/apps/novatiny/config/#{environment}"

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
  run "ln -s #{config_path}/environments/#{environment}.yml #{release_path}/config/environments/#{environment}.yml"
  run "ln -s #{config_path}/environments/#{environment}.rb  #{release_path}/config/environments/#{environment}.rb"
end

desc "Full deployment cycle"
task "vlad:deploy" => %w[
  vlad:update
  symlink
  vlad:start_app
]
