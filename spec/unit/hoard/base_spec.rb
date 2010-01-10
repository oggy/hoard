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

    it "should add no support files by default" do
      hoard = make_hoard
      hoard.support_files.should == {}
    end

    it "should make needy files optional if the :needy_files_optional option is true" do
      hoard = make_hoard(:needy_files_optional => true)
      hoard.needy_files_optional.should be_true
    end

    it "should not make needy files optional by default" do
      hoard = make_hoard
      hoard.needy_files_optional.should be_false
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

    describe "when creating the hoard" do
      before do
        # Create the hoard directory too, to make sure that doesn't
        # affect things.
        write_file('HOARD/metadata.yml', {'load_path' => ['1']}.to_yaml)
        FileUtils.mkdir_p 'HOARD/1'
      end

      it "should not modify the load path" do
        Dir.mkdir 'original'
        @load_path << 'original'
        make_hoard(:create => true)
        @load_path.should == ['original']
      end

      it "should not prevent further modifications to the load path" do
        make_hoard(:create => true)
        @load_path << 'new'
        @load_path.last.should == 'new'
      end
    end

    describe "when not creating the hoard" do
      describe "when the hoard does not exist" do
        it "should not modify the load path" do
          Dir.mkdir 'original'
          @load_path << 'original'
          make_hoard(:create => false)
          @load_path.should == ['original']
        end

        it "should not prevent further modifications to the load path" do
          make_hoard(:create => false)
          @load_path << 'new'
          @load_path.last.should == 'new'
        end
      end

      describe "when the hoard exists" do
        before do
          write_file('HOARD/metadata.yml', {'load_path' => ['1']}.to_yaml)
          FileUtils.mkdir_p 'HOARD/1'
        end

        it "should set the load path to the layers of the hoard" do
          @load_path.clear
          make_hoard(:create => false)
          @load_path.should == ['./HOARD/1']
        end

        it "should prevent further modifications to the load path" do
          make_hoard(:create => false)
          @load_path << 'new'
          @load_path.last.should_not == 'new'
        end
      end
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
    end

    describe "when not creating the hoard" do
      before do
        @hoard = make_hoard(:create => false, :hoard_path => 'HOARD')
      end

      describe "when the hoard has not been created" do
        it "should not create the hoard" do
          @hoard.ready
          File.should_not be_directory('HOARD')
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

      it "should drop a file if it collides with an existing directory in one layer, and a file in another" do
        write_file 'A/x/file', 'A/x/file'
        write_file 'B/x', 'B/x'
        write_file 'C/x', 'C/x'
        @load_path << 'A' << 'B' << 'C'
        @hoard.create
        File.read('HOARD/1/x/file').should == 'A/x/file'
        File.read('HOARD/2/x').should == 'B/x'
      end
    end

    describe "when support files are specified" do
      before do
        @load_path << 'A' << 'B'
      end

      it "should add all the specified support files for a given load path directory" do
        write_file 'A/a'
        write_file 'A/b'
        write_file 'a_support'
        write_file 'b_support'
        @hoard.support_files = {
          'A' => {
            'a' => '../a_support',
            'b' => '../b_support',
          }
        }
        @hoard.create
        File.read('HOARD/1/__hoard__/a').should == 'A/a'
        File.read('HOARD/1/__hoard__/b').should == 'A/b'
        File.read('HOARD/1/a_support').should == 'a_support'
        File.read('HOARD/1/b_support').should == 'b_support'
      end

      it "should add support files for all the given load path directories" do
        write_file 'A/a'
        write_file 'B/b'
        write_file 'a_support'
        write_file 'b_support'
        @hoard.support_files = {
          'A' => {'a' => '../a_support'},
          'B' => {'b' => '../b_support'},
        }
        @hoard.create
        File.read('HOARD/1/__hoard__/a').should == 'A/a'
        File.read('HOARD/1/__hoard__/b').should == 'B/b'
        File.read('HOARD/1/a_support').should == 'a_support'
        File.read('HOARD/1/b_support').should == 'b_support'
      end

      it "should successfully add support files for paths inside directories that are symlinked in the hoard" do
        write_file 'A/dir/file'
        write_file 'support'
        @hoard.support_files = {
          'A' => {'dir/file' => '../../support'},
        }
        @hoard.create
        File.read('HOARD/1/__hoard__/dir/file').should == 'A/dir/file'
        File.read('HOARD/1/support').should == 'support'
      end

      it "should automatically create directories for the support file symlinks" do
        write_file 'A/a'
        write_file 'support/file'
        @hoard.support_files = {'A' => {'a' => '../support/file'}}
        @hoard.create
        File.read('HOARD/1/__hoard__/a').should == 'A/a'
        File.read('HOARD/1/support/file').should == 'support/file'
      end

      it "should set the layer paths in the hoard metadata file" do
        write_file 'A/a'
        write_file 'a_support'
        @hoard.support_files = {'A' => {'a' => '../a_support'}}
        @hoard.create
        YAML.load_file('HOARD/metadata.yml')['load_path'].should == ['1/__hoard__']
      end

      it "should allow multiple support files per needy file" do
        write_file 'A/a'
        write_file 'support1'
        write_file 'support2'
        @hoard.support_files = {'A' => {'a' => ['../support1', '../support2']}}
        @hoard.create
        File.read('HOARD/1/support1').should == 'support1'
        File.read('HOARD/1/support2').should == 'support2'
      end

      describe "when needy files are optional" do
        before do
          @hoard.needy_files_optional = true
        end

        it "should ignore missing needy files" do
          write_file 'A/support'
          @hoard.support_files = {
            'A' => {'missing' => '../support'}
          }
          lambda{@hoard.create}.should_not raise_error(RuntimeError)
        end

        it "should raise an error if a support file is missing" do
          write_file 'A/file'
          @hoard.support_files = {
            'A' => {'file' => '../missing'}
          }
          lambda{@hoard.create}.should raise_error(RuntimeError)
        end
      end

      describe "when needy files are not optional" do
        before do
          @hoard.needy_files_optional = false
        end

        it "should raise an error if a needy file is missing" do
          write_file 'A/support'
          @hoard.support_files = {
            'A' => {'missing' => '../support'}
          }
          lambda{@hoard.create}.should raise_error(RuntimeError)
        end

        it "should raise an error if a support file is missing" do
          write_file 'A/file'
          @hoard.support_files = {
            'A' => {'file' => '../missing'}
          }
          lambda{@hoard.create}.should raise_error(RuntimeError)
        end
      end
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
