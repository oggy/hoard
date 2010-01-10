require 'pathname'
require 'fileutils'

require 'hoard/error'

require 'hoard/base'
require 'hoard/rubygems'
require 'hoard/rails'

module Hoard
  class << self
    #
    # Initialize Hoard.
    #
    # Each argument is either a hash of options or the name of a YAML
    # file which contains such a hash.  Options in later arguments
    # override earlier ones.
    #
    # Options are below, and may be given by either a string or symbol
    # key.
    #
    # TODO: document the options
    #
    def init(*args)
      guard :init, "Hoard.init already called"
      config = {}
      args.each do |arg|
        merge_config(config, arg)
      end
      if config.key?(:creating)
        @creating = config[:creating]
      else
        config[:creating] = creating?
      end
      @hoard = type_to_class(config[:type] || :base).new(config)
    end

    #
    # The hoard instance in use.
    #
    # Set by Hoard.init.
    #
    attr_accessor :hoard

    #
    # Declare that the application's load path is set up, and ready
    # for hoarding.
    #
    # When creating the hoard, all directories in the load path at
    # this point in the program are hoarded.  Otherwise, the load path
    # is replaced with the hoard directory.
    #
    def ready
      guard :ready, "Hoard.ready already called"
      @hoard or
        raise Error, "Hoard not initialized.  Call Hoard::Base.init or that of a Hoard::Base subclass."
      @hoard.ready
    end

    #
    # Say whether or not we're creating the hoard directory.  Default
    # is false.
    #
    # Usually set by a rake task or similar.
    #
    def creating=(value)
      hoard and
        raise Error, "Hoard already initialized"
      @creating = value
    end

    #
    # Return whether or not we're creating the hoard directory.
    #
    def creating?
      if hoard
        hoard.creating?
      else
        @creating
      end
    end

    #
    # Reset Hoard.
    #
    # (Intended for testing.)
    #
    def reset!
      @hoard = nil
      @creating = nil
      @guards = nil
    end

    private  # -------------------------------------------------------

    def guard(name, error_message)
      @guards ||= {}
      @guards[name] and
        raise Error, error_message
      @guards[name] = true
    end

    def merge_config(master_config, config)
      case config
      when String
        require 'yaml'
        config = YAML.load_file(config)
      when Symbol
        config = {:type => config}
      end
      config.each do |key, value|
        master_config[key.to_sym] = value
      end
    end

    def type_to_class(type)
      type = type.to_s
      name = type.gsub(/(?:_|\A)(.)/){$1.capitalize}
      const_get(name)
    end
  end
end
