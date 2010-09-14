#!/usr/bin/env rake
begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'rake'
require 'rake/testtask'

# $:.unshift(File.expand_path('lib'))

Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/*_test.rb'
  t.libs << 'test'
  t.ruby_opts << "-rubygems -rtest -reko"
  t.warning = false
  t.verbose = true
end

task :default => :test


desc 'Launch an IRB console'
task :console do
  libs = "-reko -rirb/completion"
  exec "irb #{libs}"
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.pattern = 'test/**/test_*.rb'
    t.libs << 'test_setup'
    t.ruby_opts << "-rubygems -reko"
    t.warning = false
    t.verbose = true
  end
rescue LoadError
end


desc "Load all the codes"
task :environment do
  require 'eko'
end

namespace :db do

  desc "Migrate up to the latest schema"
  task :migrate => :environment do
    require 'sequel/extensions/migration'
    # Sequel::Migrator.apply(Eko.connection, File.join(File.dirname(__FILE__), "db", "migrate"), 0)
    Sequel::Migrator.apply(Eko.connection, File.join(File.dirname(__FILE__), "db", "migrate"))
  end

end