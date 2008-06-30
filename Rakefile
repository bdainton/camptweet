# -*- ruby -*-

require 'rubygems'
require 'rake/testtask'
require 'echoe'

Echoe.new('camptweet') do |p|
  p.author = "Brian Dainton"
  p.summary = "A simple daemon that polls for updated Twitter statuses, 
    Twitter search results, and RSS/Atom feed content and posts 
    them to a Campfire room."
  p.url = "http://github.com/bdainton/camptweet"
  p.dependencies = ["twitter4r >=0.3.0", "tinder >=0.1.6", "simple-rss"]
end


task :default => :test

desc 'Run all tests'
Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

# vim: ft=ruby sw=2 ts=2 ai