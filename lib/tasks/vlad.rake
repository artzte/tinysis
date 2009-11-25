begin
  require "vlad"
  Vlad.load(:app => :passenger, :scm => "git")
  rescue LoadError
  # do nothing
end

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
