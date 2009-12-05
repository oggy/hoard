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
      Hoard.init(:test)
      Hoard.hoard.should be_a(Hoard::Test)
    end

    it "should pass any given options to the hoard" do
      Hoard.init(:test, :a => 1)
      Hoard.hoard.options[:a].should == 1
    end
  end
end
