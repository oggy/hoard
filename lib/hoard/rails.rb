require 'hoard'

module Hoard
  #
  # To use Hoard with a Rails application, add this in
  # <tt>config/environment.rb</tt>:
  #
  #     require 'hoard/rails'
  #
  # For best results, put it right after <tt>config/boot.rb</tt> is
  # loaded.  Configuration will be taken from
  # <tt>config/hoard.yml</tt>.
  #
  # <tt>Hoard.ready</tt>, which declares the point at which point the
  # load path is ready for caching, will be called automatically after
  # the call to Rails::Initializer.run.  This can be disabled by
  # setting the :autoready option to false.  In this case, you must
  # call <tt>Hoard.ready</tt> yourself.
  #
  class Rails < Rubygems
    def initialize(options={})
      @autoready = options.key?(:autoready) ? options[:autoready] : true
      super
      inject_ready_call unless !autoready
    end

    attr_accessor :autoready

    def self.read_config
      config = {}
      config_path = "#{::Rails.root}/config/hoard.yml"
      if File.exist?(config_path)
        YAML.load_file(config_path).each do |key, value|
          config[key.to_sym] = value
        end
      end
      config
    end

    private # --------------------------------------------------------

    def inject_ready_call
      class << ::Rails::Initializer
        def run_with_hoard(*args, &block)
          run_without_hoard(*args, &block)
          Hoard.ready
        end
        alias run_without_hoard run
        alias run run_with_hoard
      end
    end
  end
end

unless $HOARD_TEST
  Hoard.init :rails, Hoard::Rails.read_config
end
