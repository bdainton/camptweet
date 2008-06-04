# -*- ruby -*-
#$LOAD_PATH << "lib"
#$LOAD_PATH << "plugins/taxonomy/lib"

require 'rubygems'
require 'rake/testtask'
require 'echoe'

Echoe.new('camptweet')

task :default => :test

desc 'Run all tests'
Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

# vim: ft=ruby sw=2 ts=2 ai