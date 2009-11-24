#!/usr/bin/env ruby

# For various deployment targets, this post has good information
# http://withoutscope.com/2007/9/17/vlad-my-new-secret-love
# for database.yml and similar configs, this has good information
# http://obvio171.wordpress.com/2008/01/12/making-vlad-copy-databaseyml-to-shared-folder/
#
set :rails_env,   "production"
set :deploy_to,   "/var/apps/novatiny/#{rails_env}"
