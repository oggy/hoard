Given /^a gem "(.*?)" containing the following files:$/ do |name, files|
  version = '0.0.1'
  paths = files.hashes.map{|hash| hash[:path]}
  make_gem(name, version, files.hashes)
  make_specification(name, version, paths)
end

Given /^gem "(.*?)" has a require path "(.*?)"$/ do |name, path|
  version = '0.0.1'
  add_require_path(name, version, path)
end

Then /^"(.*?)" should be a symlink to "(.*?)" in gem "(.*?)"$/ do |symlink, target, name|
  version = '0.0.1'
  target = File.join(gem_path(name, version), target)

  File.should be_symlink(symlink)
  absolute_target = File.expand_path(target)
  relative_target = Pathname(target).relative_path_from(Pathname(symlink)).to_s
  [absolute_target, relative_target].should include(File.readlink(symlink))
end

module GemSteps
  def make_gem(name, version, files)
    FileUtils.mkdir_p gem_path(name, version)
    files.each do |file|
      FileUtils.mkdir_p File.dirname(file[:path])
      path = File.join(gem_path(name, version), file[:path])
      write_file path, file[:content]
    end
  end

  def make_specification(name, version, paths)
    FileUtils.mkdir_p "specifications"
    specification = Gem::Specification.new do |s|
      s.name = name
      s.version = version
      s.summary = 'Summary'
      s.require_paths = []
    end
    write_specification(specification)
  end

  def add_require_path(name, version, path)
    specification_path = specification_path(name, version)
    specification = eval( File.read(specification_path) )
    specification.require_paths << path
    write_specification(specification)
  end

  private  # ---------------------------------------------------------

  def gem_path(name, version)
    "gem_repo/gems/#{name}-#{version}"
  end

  def specification_path(name, version)
    "gem_repo/specifications/#{name}-#{version}.gemspec"
  end

  def write_specification(specification)
    path = specification_path(specification.name, specification.version)
    write_file(path, specification.to_ruby)
  end

  def write_file(path, content)
    FileUtils.mkdir_p File.dirname(path)
    open(path, 'w'){|f| f.puts content}
  end
end

World GemSteps
