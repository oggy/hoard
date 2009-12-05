require 'rbconfig'
require 'fileutils'

ROOT = File.expand_path('../../..', __FILE__)
WORKSPACE_DIR = "#{ROOT}/tmp"

Before do
  FileUtils.mkdir_p(WORKSPACE_DIR)
  Dir.chdir WORKSPACE_DIR
end

After do
  FileUtils.rm_rf(WORKSPACE_DIR)
end
