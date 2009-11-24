set :application, "novatiny"
set :domain,      "74.63.3.51"
set :repository, 'http://www.tinysis.org/tinysis/branches/barth'
set :web_command, "/bin/true"
set :svn_cmd, "svn --username=\"baddabig\" --password=\"bbkaiburr72\""

set :config_files, ['database.yml']

namespace :vlad do  

  desc "Deploys"  
  remote_task :deploy do  
  end
  
  task :setup => []

  task :deploy => [:update, :symlink, :start]

  remote_task :symlink do
    run "ln -s #{shared_path}/assets/gradesheet #{release_path}/public/assets/gradesheet"
  end

end  

