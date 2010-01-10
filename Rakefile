require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "hoard"
    gem.summary = "Speeds up the load time of Ruby programs."
    gem.description = <<-EOS.gsub(/^ *\|/, '')
      |When your load path is long, each #require or #load call must
      |stat a large number of files before it can load the file.
      |Since a long load path usually goes hand-in-hand with loading a
      |large number of files, this can quickly lead to intolerable
      |load times.
      |
      |Hoard helps by creating a minimal directory of symlinks which
      |point to the directories in your load path.  It can accomodate
      |libraries whose load path directories collide, and which
      |require support files outside their load path directories.
      |Extra support is included for programs using Rubygems and Rails
      |applications.
    EOS
    gem.email = "george.ogata@gmail.com"
    gem.homepage = "http://github.com/oggy/hoard"
    gem.authors = ["George Ogata"]
    gem.add_development_dependency "rspec", "~> 1.2.9"
    gem.add_development_dependency "cucumber", "~> 0.6.1"
    gem.add_development_dependency "rspec_outlines", "~> 0.0.1"
    gem.add_development_dependency "mocha", "~> 0.9.8"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'

desc "Run specs."
Spec::Rake::SpecTask.new(:spec => :check_dependencies) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/unit/**/*_spec.rb']
end

require 'cucumber/rake/task'

desc 'Run features.'
Cucumber::Rake::Task.new(:cucumber => :check_dependencies) do |t|
  t.fork = false
  t.cucumber_opts = "--color --strict --format #{ENV['CUCUMBER_FORMAT'] || 'pretty'}"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Hoard #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => [:spec, :cucumber]
