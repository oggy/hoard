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
    yield GemHelper.new(spec)
  end

  describe "#create" do
    it "should add the configured gem support files" do
      make_gem 'first', '0.0.1' do |gem|
        gem.file 'lib/first.rb'
        gem.file 'data/file'
      end
      make_gem 'second', '0.0.2' do |gem|
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
      @load_path << 'gems/first-0.0.1/lib' << 'gems/second-0.0.2/lib' << 'gems/second-0.0.2/bin'
      @hoard.create

      File.read('HOARD/1/__hoard__/first.rb').should == 'lib/first.rb'
      File.read('HOARD/1/data/file').should == 'data/file'
    end

    it "should merge gem support files with regular support files" do
      write_file 'mylib/mylib.rb'
      write_file 'data/mylib_file'
      make_gem 'mygem', '0.0.1' do |gem|
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
      @load_path << 'mylib' << 'gems/mygem-0.0.1/lib'
      @hoard.create
      File.read('HOARD/1/__hoard__/mylib.rb').should == 'mylib/mylib.rb'
      File.read('HOARD/1/data/mylib_file').should == 'data/mylib_file'
      File.read('HOARD/1/__hoard__/mygem.rb').should == 'lib/mygem.rb'
      File.read('HOARD/1/data/mygem_file').should == 'data/mygem_file'
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

      # 'gems/mygem-0.0.1/lib' not added to load path
      @hoard.create
      File.should_not exist('HOARD/1/data/file')
    end

    it "should add support gem files to the same layer as the corresponding needy file" do
      make_gem 'first', '0.0.1' do |gem|
        gem.file 'lib/test'
        gem.file 'data/first'
      end
      make_gem 'second', '0.0.1' do |gem|
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
      @load_path << 'gems/first-0.0.1/lib' << 'gems/second-0.0.1/lib'
      @hoard.create

      File.read('HOARD/1/__hoard__/test/test').should == 'lib/test/test'
      File.read('HOARD/1/data/second').should == 'data/second'
      File.read('HOARD/2/__hoard__/test').should == 'lib/test'
      File.read('HOARD/2/data/first').should == 'data/first'
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