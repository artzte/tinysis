require 'jammit'

namespace :assets do

  desc "Generate assets"

  task :package => :environment do
    Jammit.package!
  end

end
