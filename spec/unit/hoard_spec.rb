require 'spec_helper'

describe Hoard do
  describe ".init" do
    use_temporary_attribute_value Hoard, :hoard, nil
    use_temporary_constant_value Hoard, :Test do
      Class.new(Hoard::Base) do
        def initialize(options)
          @options = options
        end
        attr_reader :options
      end
    end

    it "should initialize a base hoard by default" do
      Hoard.init
      Hoard.hoard.should be_a(Hoard::Base)
    end

    it "should initialize a hoard of the given type by default" do
      Hoard.init(:type => :test)
      Hoard.hoard.should be_a(Hoard::Test)
    end

    it "should pass any given options to the hoard" do
      Hoard.init(:type => :test, :a => 1)
      Hoard.hoard.options[:type].should == :test
      Hoard.hoard.options[:a].should == 1
    end

    it "should allow a cascade of configurations" do
      Hoard.init({:type => :test, :a => 1}, {:a => 2})
      Hoard.hoard.options[:type].should == :test
      Hoard.hoard.options[:a].should == 2
    end

    it "should look for a YAML file if a file name is given" do
      options = {:a => 1}
      open('config.yml', 'w'){|f| f.puts options.to_yaml}
      Hoard.init({:type => :test}, 'config.yml')
      Hoard.hoard.options[:type].should == :test
      Hoard.hoard.options[:a].should == 1
    end
  end

  describe ".creating?" do
    describe "before Hoard is initialized" do
      it "should return the value of the creating flag if set" do
        Hoard.create = true
        Hoard.should be_creating

        Hoard.create = false
        Hoard.should_not be_creating
      end

      it "should default to false" do
        Hoard.should_not be_creating
      end
    end

    describe "after Hoard is initialized" do
      before do
        Hoard.init
      end

      it "should return the value of the creating flag if set" do
        Hoard.create = true
        Hoard.should be_creating

        Hoard.create = false
        Hoard.should_not be_creating
      end

      it "should default to false" do
        Hoard.should_not be_creating
      end
    end

    describe "after Hoard is initialized, when the flag was set before Hoard was initialized" do
      it "should return true if the flag was set to true" do
        Hoard.create = true
        Hoard.init
        Hoard.should be_creating
      end

      it "should return false if the flag was set to false" do
        Hoard.create = false
        Hoard.init
        Hoard.should_not be_creating
      end
    end
  end
end
