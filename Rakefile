#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

TinySIS::Application.load_tasks

begin
  require 'vlad'
  Vlad.load(:app => :passenger, :scm => "git")
rescue LoadError
  abort "Failed to load vlad"
end
