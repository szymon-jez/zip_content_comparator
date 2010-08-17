require 'rubygems'
require 'rake'
require 'rake/clean'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "zip_content_comparator"
    gem.summary = %Q{An utility for comparing content of ZIP files.}
    gem.description = <<-TEXT
An utility for comparing content of ZIP files.
It does not extract the files anywhere, its's using instead ZIP::ZipFile class
from rubyzip gem which enables to access ZIP files like a file system.
It uses MD5 to compare files.
TEXT
    gem.email = "szymon@jez.net.pl"
    gem.homepage = "http://github.com/jeznet/zip_content_comparator"
    gem.authors = ["Szymon (jeznet) Jeż"]
    gem.add_dependency('rubyzip', '>= 0.9.1')
    # gem.requirements << ''
    # gem.add_development_dependency "thoughtbot-shoulda"
    # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  # test.pattern = 'test/**/*_test.rb'
  test.test_files = FileList['test/**/*suite.rb']
  test.verbose = true
  # require 'test_notifier/test_unit'
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "Zip File Content Comparator #{version}"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
  rdoc.options << '--charset=utf-8'
end

# load tasks
Dir['tasks/**/*.rake'].each { |rake| load rake }