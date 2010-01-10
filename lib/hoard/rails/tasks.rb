desc "Create the hoard directory."
task :hoard do
  require 'hoard'
  Hoard.create = true
  Rake::Task['environment'].invoke
end
