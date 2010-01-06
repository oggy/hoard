require 'ruby-debug'
require 'rbconfig'
require 'fileutils'
require 'pathname'


ROOT = File.expand_path('../../..', __FILE__)
WORKSPACE_DIR = "#{ROOT}/tmp"

Before do
  FileUtils.mkdir_p(WORKSPACE_DIR)
  @starting_directory = Dir.pwd
  Dir.chdir WORKSPACE_DIR
end

After do
  Dir.chdir @starting_directory
  FileUtils.rm_rf(WORKSPACE_DIR)
end

def ruby
  File.join(Config::CONFIG['bindir'], Config::CONFIG['RUBY_INSTALL_NAME'])
end
