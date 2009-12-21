require 'spec_helper'

describe Hoard::Base::Layer do
  Layer = Hoard::Base::Layer
  describe "#initialize" do
    before do
      @layer = Layer.new('layer', 2)
    end

    it "should have the given #number" do
      @layer.number.should == 2
    end

    it "should have a path named with the number, under the hoard path" do
      @layer.path.should == 'layer/2'
    end

    it "should create the layer directory" do
      File.should be_directory(@layer.path)
    end
  end

  describe "#file?" do
    before do
      @layer = Layer.new('hoard', 2)
    end

    it "should return true if the given path is a nondirectory file under the layer path" do
      FileUtils.touch('hoard/2/file')
      @layer.file?('file').should be_true
    end

    it "should return false if the given path is a directory under the layer path" do
      FileUtils.mkdir_p('hoard/2/file')
      @layer.file?('file').should be_false
    end

    it "should return true if the given path is a symlink to a file under the layer path" do
      FileUtils.touch('target')
      File.symlink('../../target', 'hoard/2/file')
      @layer.file?('file').should be_true
    end

    it "should return false if the given path is a symlink to a directory under the layer path" do
      FileUtils.mkdir_p('target')
      File.symlink('../../target', 'hoard/2/file')
      @layer.file?('file').should be_false
    end
  end
end
