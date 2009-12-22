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

    it "should have a root named with the number, under the hoard path" do
      @layer.root.should == 'layer/2'
    end

    it "should have a #path the same as the #root" do
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

    describe "when the layer has been pushed down a directory" do
      it "should return true if the given path is a file under the layer path" do
        @layer.depth = 1
        FileUtils.touch 'hoard/2/__hoard__/file'
        @layer.file?('file').should be_true
      end

      it "should return false if the given path is a file under the root, but not under the layer path" do
        @layer.depth = 1
        FileUtils.touch 'hoard/2/file'
        @layer.file?('file').should be_false
      end
    end
  end

  describe "#depth=" do
    before do
      @layer = Layer.new('hoard', 2)
    end

    it "should set the depth to the given value" do
      @layer.depth = 3
      @layer.depth.should == 3
    end

    def directory_tree(path)
      io = StringIO.new
      directory_tree_recursive(path, io, '')
      io.string
    end

    def directory_tree_recursive(path, io, prefix)
      Dir["#{path}/*"].each do |child|
        io.puts "#{prefix}#{File.basename(child)}"
        if File.directory?(child)
          directory_tree_recursive(child, io, prefix + '  ')
        end
      end
    end

    before do
      FileUtils.touch('hoard/2/file')

      # sanity check
      directory_tree('hoard/2').should == <<-EOS.gsub(/^ *\|/, '')
        |file
      EOS
    end

    describe "when the depth is initially 0" do
      it "should not change the directory tree if the depth is set to 0" do
        @layer.depth = 0
        directory_tree('hoard/2').should == <<-EOS.gsub(/^ *\|/, '')
          |file
        EOS
      end

      it "should push the layer directory down 2 directories if the depth is set to 2" do
        @layer.depth = 2
        directory_tree('hoard/2').should == <<-EOS.gsub(/^ *\|/, '')
          |__hoard__
          |  __hoard__
          |    file
        EOS
      end

      describe "after the depth has been pushed to 2" do
        before do
          @layer.depth = 2
        end

        it "should pull the layer directory up a directory if the depth is set to 1" do
          @layer.depth = 1
          directory_tree('hoard/2').should == <<-EOS.gsub(/^ *\|/, '')
            |__hoard__
            |  file
          EOS
        end

        it "should pull the layer directory back to the top if the depth is set to 0" do
          @layer.depth = 0
          directory_tree('hoard/2').should == <<-EOS.gsub(/^ *\|/, '')
            |file
          EOS
        end

        it "should push the layer directory down another directory if the depth is set to 3" do
          @layer.depth = 3
          directory_tree('hoard/2').should == <<-EOS.gsub(/^ *\|/, '')
            |__hoard__
            |  __hoard__
            |    __hoard__
            |      file
          EOS
        end
      end
    end
  end
end
