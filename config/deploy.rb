set :environment, ENV["env"]||"development"

set :application, "novatiny"
set :domain,      "74.63.3.51"
set :repository, 'git://github.com/artzte/tinysis.git'
set :deploy_to, "/var/apps/novatiny/#{environment}"
set :config_files, ['database.yml']
set :web_command, "sudo apachectl"


task :remote_path do
  puts remote_path
end

remote_task :symlink do
  run "if [[ ! -d \"#{shared_path}/assets/gradesheet\" ]]; then mkdir -p \"#{shared_path}/assets/gradesheet\"; fi"
  run "if [[ ! -d \"#{release_path}/public/assets\" ]]; then mkdir -p \"#{release_path}/public/assets\"; fi"
  run "ln -s #{shared_path}/assets/gradesheet #{release_path}/public/assets/gradesheet"
  run "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"
end

desc "Full deployment cycle"
task "vlad:deploy" => %w[
  vlad:update
  symlink
]
