Gem::Specification.new do |s|
  s.name = 'camptweet'
  s.version = '0.8.1'
  s.authors = ['Brian Dainton']
  s.email = 'brian.dainton@gmail.com'
  s.homepage = 'http://github.com/bdainton/camptweet'
  s.summary = 'A simple daemon that polls for updated Twitter statuses and posts them to a Campfire room.'
  s.description = s.summary
  s.require_path = 'lib'
  s.executables = ["camptweet", "camptweetd_base"]  
  s.files = ["bin/camptweet", "bin/camptweetd_base", "CHANGELOG", "init.rb", "lib/camptweet/bot.rb", "lib/camptweet.rb", "LICENSE", "README.rdoc", "Manifest", "camptweet.gemspec"]   
  s.add_dependency('twitter4r', [">= 0.3.0"])
  s.add_dependency('tinder', [">= 0.1.6"])
end
