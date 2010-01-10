desc "Create the hoard directory."
task :hoard do
  require 'hoard'
  Hoard.creating = true
  Rake::Task['environment'].invoke
end
