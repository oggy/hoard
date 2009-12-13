Given /^the "(.*?)" environment variable is set$/ do |name|
  env[name] = '1'
end

Given /^the "(.*?)" environment variable is unset$/ do |name|
  env.delete(name)
end

Given /^the hoard has been created$/ do
  `#{env_string} #{ruby} #{path} 2>&1`
end

When /^"(.*?)" is run$/ do |path|
  @output = `#{env_string} #{ruby} #{path} 2>&1`
  $?.success? or
    raise "command failed - output: #{@output}"
end

Then /^there should be no output$/ do
  @output.should == ''
end

Then /^the output should be:/ do |output|
  @output.should == "#{output}\n"
end

Then /^the output should contain:/ do |output|
  @output.should include(output)
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
