require 'spec_helper'

describe Hoard::Base do
  before do
    @load_path = []
  end

  def make_hoard(options={})
    defaults = {
      :hoard_path => 'HOARD',
      :load_path => @load_path,
      :after_create => lambda{@would_have_exited = true},
    }
    @would_have_exited = false
    Hoard::Base.new(defaults.merge(options))
  end

  describe "#initialize" do
    it "should set the hoard path from the :hoard_path option, if given" do
      hoard = make_hoard(:hoard_path => 'custom-hoard-path')
      hoard.hoard_path.should == 'custom-hoard-path'
    end

    it "should set a default hoard path of 'hoard'" do
      hoard = make_hoard(:hoard_path => nil)
      hoard.hoard_path.should == 'hoard'
    end

    it "should set the #creating? flag to true, if the :create option is true" do
      hoard = make_hoard(:create => true)
      hoard.should be_creating
    end

    it "should set the #creating? flag to false, if the :create option is false" do
      hoard = make_hoard(:create => false)
      hoard.should_not be_creating
    end

    it "should make the #creating? flag default to false" do
      hoard = make_hoard
      hoard.should_not be_creating
    end
  end

  describe "#ready" do
    describe "when creating the hoard" do
      before do
        @hoard = make_hoard(:create => true)
      end

      it "should create the hoard" do
        @hoard.ready
        File.should be_directory('HOARD')
      end

      it "should exit" do
        @hoard.ready
        @would_have_exited.should be_true
      end

      it "should not modify the load path" do
        Dir.mkdir 'original'
        @load_path << 'original'
        @hoard.ready
        @load_path.should == ['original']
      end
    end

    describe "when not creating the hoard" do
      before do
        @hoard = make_hoard(:create => false, :hoard_path => 'HOARD')
      end

      describe "when the hoard has not been created" do
        it "should not try to use the hoard" do
          Dir.mkdir 'original'
          @load_path << 'original'
          @hoard.ready
          @load_path.should == ['original']
        end

        it "should not exit" do
          @hoard.ready
          @would_have_exited.should be_false
        end

        it "should not create the hoard" do
          @hoard.ready
          File.should_not be_directory('HOARD')
        end
      end

      describe "when the hoard directory exists" do
        before do
          FileUtils.mkdir_p 'HOARD/1'
        end

        it "should use the hoard" do
          @hoard.ready
          @load_path.should == ['HOARD/1']
        end

        it "should not exit" do
          @hoard.ready
          @would_have_exited.should be_false
        end
      end
    end
  end

  describe "#create" do
    before do
      @hoard = make_hoard(:hoard_path => 'HOARD')
    end

    #
    # Create a file at the given path, creating parent directories as
    # needed.
    #
    def write_file(path, content)
      FileUtils.mkdir_p File.dirname(path)
      open(path, 'w'){|f| f.print content}
    end

    it "should create the hoard directory" do
      @hoard.create
      File.should be_directory('HOARD')
    end

    it "should be able to create the hoard in a directory that does not yet exist" do
      @hoard.hoard_path = "HOARD/HOARD"
      @hoard.create
      File.should be_directory('HOARD/HOARD')
    end

    it "should ignore entries in the load path that don't exist" do
      @load_path << 'A'
      File.should_not exist('A')
      lambda{@hoard.create}.should_not raise_error
    end

    it "should ignore entries in the load path that are not directories" do
      FileUtils.touch 'A'
      lambda{@hoard.create}.should_not raise_error
    end

    it "should include entries in the load path that are symlinks to directories" do
      write_file 'A/a', 'a'
      File.symlink 'A', 'B'
      @load_path << 'B'
      @hoard.create
      File.directory?('HOARD/1/B')
    end

    describe "adding multiple paths to the hoard" do
      outline "it should :description" do
        write_file "A/#{path1}", 'a'
        write_file "B/#{path2}", 'b'
        @load_path << 'A' << 'B'
        @hoard.create
        File.read("HOARD/#{link1}").should == 'a'
        File.read("HOARD/#{link2}").should == 'b' unless link2.nil?

        # check files aren't shadowed if in layer 2
        File.should_not be_file(link1.sub(/1/, '2')) if link1 =~ /^2/
        File.should_not be_file(link2.sub(/1/, '2')) if link2 && link2 =~ /^2/
      end

      fields :path1 , :path2 , :link1   , :link2   , :description

      values 'a'    , 'b'    , '1/a'    , '1/b'    , "add both entries to the first layer when they do not collide"

      values 'a/f'  , 'a/g'  , '1/a/f'  , '1/a/g'  , "merge in the first layer when there's a directory/directory collision"
      values 'a/f'  , 'a'    , '1/a/f'  , '2/a'    , "put the file in the second layer when there's a directory/file collision"
      values 'a'    , 'a/f'  , '2/a'    , '1/a/f'  , "put the file in the second layer when there's a file/directory collision"
      values 'a'    , 'a'    , '1/a'    , nil      , "not add the second file when there's a file/file collision"

      values 'x/a/f', 'x/a/g', '1/x/a/f', '1/x/a/g', "merge in the first layer when there's a deep directory/directory collision"
      values 'x/a/f', 'x/a'  , '1/x/a/f', '2/x/a'  , "put the file in the second layer when there's a deep directory/file collision"
      values 'x/a'  , 'x/a/f', '2/x/a'  , '1/x/a/f', "put the file in the second layer when there's a deep file/directory collision"
      values 'x/a'  , 'x/a'  , '1/x/a'  , nil      , "not add the second file when there's a deep file/file collision"

      it "should create a third layer if there are collisions in the first two" do
        write_file 'A/a', 'a'
        write_file 'B/a/b', 'b'
        write_file 'C/a/b/c', 'c'
        @load_path << 'A' << 'B' << 'C'
        @hoard.create
        File.read('HOARD/1/a/b/c').should == 'c'
        File.read('HOARD/2/a/b').should == 'b'
        File.read('HOARD/3/a').should == 'a'
      end
    end
  end

  describe "#use" do
    before do
      @hoard = make_hoard(:hoard_path => 'HOARD')
    end

    it "should not modify the load path if the hoard directory doesn't exist" do
      @load_path << 'original'
      @hoard.use
      @load_path.should == ['original']
    end

    it "should not modify the load path if no hoard layers were found" do
      @load_path << 'original'
      FileUtils.mkdir_p 'HOARD/X'
      @hoard.use
      @load_path.should == ['original']
    end

    it "should set the load path to the hoard layer directories, sorted numerically" do
      Dir.mkdir 'HOARD'
      (1..100).sort_by{rand}.each{|i| Dir.mkdir "HOARD/#{i}"}
      @hoard.use
      @load_path.should == (1..100).map{|i| "HOARD/#{i}"}
    end

    it "should not include directories in the hoard which aren't named with a number" do
      FileUtils.mkdir_p "HOARD/1"
      FileUtils.mkdir_p "HOARD/2A"
      FileUtils.mkdir_p "HOARD/X"
      @hoard.use
      @load_path.should == ['HOARD/1']
    end
  end

  describe "#create=" do
    it "should set the value of the #creating? flag" do
      hoard = make_hoard
      hoard.create = true
      hoard.should be_creating
    end
  end
end