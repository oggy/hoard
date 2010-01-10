Given /^the "(.*?)" environment variable is set$/ do |name|
  env[name] = '1'
end

Given /^the "(.*?)" environment variable is unset$/ do |name|
  env.delete(name)
end

When /^we switch to the "(.*?)" directory$/ do |path|
  Dir.chdir path
end

When /^"(.*?)" is run$/ do |command|
  command = command.dup  # else cuke output is screwed up
  if command.gsub!(/^ruby /, '')
    command.insert(0, "#{ruby} -I \"#{ROOT}/lib\" ")
  elsif command.gsub!(/^rake /, '')
    dir, base = File.split(ruby)
    rake = "#{dir}/#{base.sub(/ruby/, 'rake')}"
    command.insert(0, "#{rake} -I \"#{ROOT}/lib\" ")
  end
  @output = `#{env_string} #{command} 2>&1`
  $?.success? or
    raise "command failed - output: #{@output}"
end

Then /^there should be no output$/ do
  @output.should == ''
end

Then /^the output should be:$/ do |output|
  @output.should == "#{output}\n"
end

Then /^the output should contain:$/ do |output|
  @output.should include(output)
end

Then /^the output should not contain "(.*?)"$/ do |output|
  @output.should_not include(output)
end

module ProgramSteps
  def env
    @env ||= {}
  end

  def env_string
    env.map{|k,v| [k,v].join('=')}.join(' ')
  end
end

World ProgramSteps
