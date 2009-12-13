require 'hoard'
require 'spec'
require 'rspec_outlines'

ROOT = File.expand_path('../..', __FILE__)

require 'spec/helpers/temporary_directory'
require 'spec/helpers/temporary_values'

Spec::Runner.configure do |config|
  config.include TemporaryDirectory
  config.include TemporaryValues
end
