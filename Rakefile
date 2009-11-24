# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'


# add these two lines for deployment
require 'vlad'
Vlad.load :app => 'passenger'

# for multiple vlad deployment locations
namespace "vlad" do
  desc "Setup the deploy target overrides"
  task :target

  rule "" do |task|
    if task.to_s.match(/vlad:target:([a-z_-]+)/i)
      override_path = File.join(RAILS_ROOT, 'config', "deploy.#{$1}.rb")
      Kernel.load override_path if File.exists? override_path
    end
  end
end

