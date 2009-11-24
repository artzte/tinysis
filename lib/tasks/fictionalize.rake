desc 'Fictionalizes the user database.'

task :fictionalize => :environment do
  include Fictionalize
  users = User.find(:all)
  fictionalize(users, :first_name, :last_name)
end
