Given /^an empty file "(.*?)"$/ do |path|
  FileUtils.mkdir_p(File.dirname(path))
  FileUtils.touch path
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

Given /^"(.*?)" is added to the file "([^\"]*)"$/ do |line, path|
  open(path, 'a'){|f| f.puts line}
end

Given /^"(.*?)" is added to the file "(.*?)" after the line containing "(.*?)"$/ do |content, path, locator|
  lines = []
  open(path) do |file|
    looking = true
    while (line = file.gets)
      lines << line
      if looking && line.include?(locator)
        lines << content << "\n"
        looking = false
      end
    end
    looking and
      raise "could not find \"#{locator}\" in "#{path}""
  end
  open(path, 'w'){|f| f.print lines.join}
end

Then /^"(.*?)" should be a directory$/ do |path|
  File.should be_directory(path)
end

Then /^"(.*?)" should not exist$/ do |path|
  File.should_not exist(path)
end

Then /^"(.*?)" should be a symlink$/ do |path|
  File.should be_symlink(path)
end

Then /^"(.*?)" should be a symlink to "([^\"]*?)"$/ do |symlink, target|
  File.should be_symlink(symlink)
  absolute_target = File.expand_path(target)
  relative_target = Pathname(target).relative_path_from(Pathname(symlink)).to_s
  [absolute_target, relative_target].should include(File.readlink(symlink))
end
