require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "hoard"
    gem.summary = "Speed up your ruby programs by caching your load path."
    gem.description = <<-EOS.gsub(/^ *\|/, '')
      |One of rubygems\' greatest inefficiencies is that having many
      |gems installed leads to a gigantic load path.  Requiring a file
      |can thus take a huge number of stat(2) calls to check each
      |directory for the right file, with one of many permissible
      |extensions.  Hoard creates a cache of files, and replaces your
      |load path with a single directory, which can dramatically speed
      |up the load time of your application.
    EOS
    gem.email = "george.ogata@gmail.com"
    gem.homepage = "http://github.com/oggy/hoard"
    gem.authors = ["George Ogata"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
namespace :spec do
  desc "Run unit specs."
  Spec::Rake::SpecTask.new(:unit => :check_dependencies) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/unit/**/*_spec.rb']
  end

  desc "Run integration specs."
  Spec::Rake::SpecTask.new(:integration => :check_dependencies) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/integration/**/*_spec.rb']
  end
end

task :spec => ['spec:unit', 'spec:integration']

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Hoard #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :spec
