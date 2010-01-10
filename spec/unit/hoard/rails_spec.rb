require 'spec_helper'

describe Hoard::Rails do
  before do
    @load_path = []
  end

  def make_hoard(options={})
    defaults = {
      :hoard_path => 'HOARD',
      :load_path => @load_path,
      :after_create => lambda{@would_have_exited = true},
      :autoready => false,
    }
    @would_have_exited = false
    Hoard::Rails.new(defaults.merge(options))
  end

  describe "#initialize" do
    before do
      Object.const_set(:Rails, OpenStruct.new)
      Rails.root = 'RAILS_ROOT'
    end

    after do
      Object.send(:remove_const, :Rails)
    end

    it "should look for configuration in RAILS_ROOT/config/hoard.yml" do
      write_file 'RAILS_ROOT/config/hoard.yml', <<-EOS.gsub(/^ *\|/, '')
        |creating: true
      EOS
      hoard = make_hoard
      hoard.should be_creating
    end
  end
end
