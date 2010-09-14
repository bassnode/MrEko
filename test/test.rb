ENV['EKO_ENV'] = 'test'
require 'bundler'
Bundler.setup
Bundler.require :test