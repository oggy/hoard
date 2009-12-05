require 'hoard/base'

module Hoard
  class << self
    #
    # Initialize Hoard.
    #
    # TODO: document
    #
    def init(*args)
      (0..2).include?(args.length) or
        raise ArgumentError, "wrong number of arguments (#{args.length} for 0..2)"
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:create] = creating? if !options.key?(:create)
      @hoard = type_to_class(args.first || :base).new(options)
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
      @hoard or
        raise RuntimeError, "Hoard not initialized.  Call Hoard::Base.init or that of a Hoard::Base subclass."
      @hoard.ready
    end

    #
    # Say whether or not we're creating the hoard directory.  Default
    # is false.
    #
    # Usually set by a rake task or similar.
    #
    def create=(value)
      if hoard
        hoard.create = value
      else
        @creating = value
      end
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

    private  # -------------------------------------------------------

    def type_to_class(type)
      type = type.to_s
      name = type.gsub(/(?:_|\A)(.)/){$1.capitalize}
      const_get(name)
    end
  end
end
