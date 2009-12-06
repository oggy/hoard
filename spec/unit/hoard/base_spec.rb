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
        @load_path = ['original']
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
          @load_path = ['original']
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
          Dir.mkdir('HOARD')
        end

        it "should use the hoard" do
          @hoard.ready
          @load_path.should == ['HOARD']
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
  end

  describe "#use" do
    before do
      @hoard = make_hoard(:hoard_path => 'HOARD')
    end

    it "should set the load path to the hoard directory" do
      @hoard.use
      @load_path.should == ['HOARD']
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
