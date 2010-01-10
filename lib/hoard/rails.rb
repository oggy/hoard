module Hoard
  #
  # To use Hoard with a Rails application, insert the following in
  # config/environment.rb:
  #
  #     require 'hoard'
  #     Hoard.init(:rails)
  #
  # For best results, this should be the first thing after loading
  # boot.rb.  Configuration will be taken from
  # <tt>config/hoard.yml</tt>.
  #
  # Hoard.ready will be called automatically after the call to
  # Rails::Initializer.run.  This can be disabled by setting the
  # :autoready option to false.
  #
  class Rails < Rubygems
    def initialize(options={})
      merge_options_from_config_file(options)
      @autoready = options.key?(:autoready) ? options[:autoready] : true

      super
      inject_ready_call unless !autoready
    end

    attr_accessor :autoready

    private # --------------------------------------------------------

    def merge_options_from_config_file(options)
      config_path = "#{::Rails.root}/config/hoard.yml"
      if File.exist?(config_path)
        config = YAML.load_file(config_path)
        config.each do |key, value|
          key = key.to_sym
          options[key] = value unless options.key?(key)
        end
      end
    end

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
