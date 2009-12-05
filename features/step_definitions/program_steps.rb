Given /^an empty file "(.*?)"$/ do |path|
  FileUtils.mkdir_p(File.dirname(path))
  FileUtils.touch(path)
end

Given /^a file "(.*?)" containing:$/ do |path, content|
  FileUtils.mkdir_p(File.dirname(path))
  open(path, 'w'){|f| f.puts content}
end

Given /^a ruby program "(.*?)" containing:$/ do |path, content|
  open(path, 'w') do |file|
    file.puts "#!#{ruby}"
    file.puts "$:.unshift('#{ROOT}/lib')"
    file.puts "eval(#{content.inspect}, binding, __FILE__, 1)"
  end
end

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

Then /^"(.*?)" should be a directory$/ do |path|
  File.should be_directory(path)
end

Then /^"(.*?)" should not exist$/ do |path|
  File.should_not exist(path)
end

module ProgramSteps
  def ruby
    File.join(Config::CONFIG['bindir'], Config::CONFIG['RUBY_INSTALL_NAME'])
  end

  def env
    @env ||= {}
  end

  def env_string
    env.map{|k,v| [k,v].join('=')}.join(' ')
  end
end
World ProgramSteps
