require 'spec_helper'

describe Hoard::Rubygems do
  before do
    @load_path = []
    @source_index = Gem::SourceIndex.new
    @hoard = make_hoard
  end

  def make_hoard(options={})
    defaults = {
      :source_index => @source_index,
      :hoard_path => 'HOARD',
      :load_path => @load_path,
      :after_create => lambda{@would_have_exited = true},
    }
    @would_have_exited = false
    Hoard::Rubygems.new(defaults)
  end

  def make_gem(name, version)
    spec = Gem::Specification.new do |spec|
      spec.name = name
      spec.version = version
      spec.stubs(:full_gem_path).returns("gems/#{name}-#{version}")
    end
    @source_index.add_spec(spec)
    yield GemHelper.new(spec) if block_given?
    spec
  end

  def load_gem(spec)
    spec.require_paths.each do |require_path|
      @load_path << File.join(spec.full_gem_path, require_path)
    end
    spec.loaded = true
  end

  describe "#create" do
    it "should add the configured gem support files" do
      first = make_gem 'first', '0.0.1' do |gem|
        gem.file 'lib/first.rb'
        gem.file 'data/file'
      end
      second = make_gem 'second', '0.0.2' do |gem|
        gem.require_paths << 'bin'
        gem.file 'bin/second'
        gem.file 'lib/second.rb'
      end
      @hoard.gem_support_files = YAML.load <<-EOS
        first:
          lib:
            first.rb: ../data/file
        second:
          bin:
            second: ../lib/second.rb
      EOS
      load_gem first
      load_gem second
      @hoard.create

      File.read('HOARD/1/__hoard__/first.rb').should == 'lib/first.rb'
      File.read('HOARD/1/data/file').should == 'data/file'
    end

    it "should merge gem support files with regular support files" do
      write_file 'mylib/mylib.rb'
      write_file 'data/mylib_file'
      mygem = make_gem 'mygem', '0.0.1' do |gem|
        gem.file 'lib/mygem.rb'
        gem.file 'data/mygem_file'
      end
      @hoard.support_files = YAML.load <<-EOS
        mylib:
          mylib.rb: ../data/mylib_file
      EOS
      @hoard.gem_support_files = YAML.load <<-EOS
        mygem:
          lib:
            mygem.rb: ../data/mygem_file
      EOS
      @load_path << 'mylib'
      load_gem mygem
      @hoard.create
      File.read('HOARD/1/__hoard__/mylib.rb').should == 'mylib/mylib.rb'
      File.read('HOARD/1/data/mylib_file').should == 'data/mylib_file'
      File.read('HOARD/1/__hoard__/mygem.rb').should == 'lib/mygem.rb'
      File.read('HOARD/1/data/mygem_file').should == 'data/mygem_file'
    end

    it "should add support gem files to the same layer as the corresponding needy file" do
      first = make_gem 'first', '0.0.1' do |gem|
        gem.file 'lib/test'
        gem.file 'data/first'
      end
      second = make_gem 'second', '0.0.1' do |gem|
        gem.file 'lib/test/test'
        gem.file 'data/second'
      end
      @hoard.gem_support_files = YAML.load <<-EOS
        first:
          lib:
            test: ../data/first
        second:
          lib:
            test/test: ../../data/second
      EOS
      load_gem first
      load_gem second
      @hoard.create

      File.read('HOARD/1/__hoard__/test/test').should == 'lib/test/test'
      File.read('HOARD/1/data/second').should == 'data/second'
      File.read('HOARD/2/__hoard__/test').should == 'lib/test'
      File.read('HOARD/2/data/first').should == 'data/first'
    end

    it "should not add support files for uninstalled gems" do
      # gem not created
      @hoard.gem_support_files = YAML.load <<-EOS
        mygem:
          lib:
            mygem.rb: ../data/file
      EOS
      @hoard.create
      File.should_not exist('HOARD/1/data/file')
    end

    it "should not add support files for unloaded gems" do
      make_gem 'mygem', '0.0.1' do |gem|
        gem.file 'lib/mygem.rb'
        gem.file 'data/file'
      end
      @hoard.gem_support_files = YAML.load <<-EOS
        mygem:
          lib:
            mygem.rb: ../data/file
      EOS

      # gem not loaded
      @hoard.create
      File.should_not exist('HOARD/1/data/file')
    end

    it "should raise an error if a needy file does not exist for a loaded gem" do
      mygem = make_gem 'mygem', '0.0.1'
      load_gem mygem
      @hoard.gem_support_files = YAML.load <<-EOS
        mygem:
          lib:
            mygem.rb: ../data/file
      EOS
      lambda{@hoard.create}.should raise_error(Hoard::Error)
    end

    it "should use the loaded version of a gem if more than one exists" do
      v001 = make_gem 'mygem', '0.0.1' do |gem|
        gem.file 'lib/mygem.rb'
        gem.file 'data/file', '0.0.1'
      end
      v002 = make_gem 'mygem', '0.0.2' do |gem|
        gem.file 'lib/mygem.rb'
        gem.file 'data/file', '0.0.2'
      end
      v003 = make_gem 'mygem', '0.0.3' do |gem|
        gem.file 'lib/mygem.rb'
        gem.file 'data/file', '0.0.3'
      end
      @hoard.gem_support_files = YAML.load <<-EOS
        mygem:
          lib:
            mygem.rb: ../data/file
      EOS
      load_gem v002
      @hoard.create
      File.read('HOARD/1/data/file').should == '0.0.2'
    end

    it "should check for gems whose full name matches the given name first" do
      matched = make_gem 'matched', '0.0.1' do |gem|
        gem.file 'lib/matched.rb'
        gem.file 'data/file', 'matched'
      end
      unmatched = make_gem 'matched-0.0.1', '0.0.1' do |gem|
        gem.file 'lib/unmatched.rb'
        gem.file 'data/file', 'unmatched'
      end
      @hoard.gem_support_files = YAML.load <<-EOS
        matched-0.0.1:
          lib:
            matched.rb: ../data/file
      EOS
      load_gem matched
      load_gem unmatched
      @hoard.create
      File.read('HOARD/1/data/file').should == 'matched'
    end
  end

  class GemHelper
    def initialize(spec)
      @spec = spec
    end

    attr_reader :spec

    def file(path_in_gem, content=path_in_gem)
      path = File.join(spec.full_gem_path, path_in_gem)
      FileUtils.mkdir_p File.dirname(path)
      open(path, 'w'){|f| f.print content}
    end

    def method_missing(*args)
      spec.send(*args)
    end
  end
end
