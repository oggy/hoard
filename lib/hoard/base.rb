module Hoard
  class Base
    #
    # Create a Hoard for any ruby application.
    #
    # Options:
    #
    #  * :create - whether or not to create the hoard.
    #  * :hoard_path - the path of the hoard directory.
    #  * :load_path - the load path array that will be modified when
    #    the hoard is #use-d.  (Intended for testing hoard classes.)
    #
    def initialize(options={}, &block)
      @hoard_path = options[:hoard_path] || 'hoard'
      @creating = options[:create] || false

      @load_path = options[:load_path] || $LOAD_PATH
      @after_create = options[:after_create] || lambda{exit}
    end

    #
    # The path of the hoard directory.
    #
    attr_reader :hoard_path

    #
    # The load path array that will be modified when the hoard is
    # #use-d.
    #
    attr_reader :load_path

    #
    # Declare that the load path is ready for hoarding.
    #
    # When creating the hoard, this will #create the hoard, and exit.
    # Otherwise, if the hoard directory exists, it will #use it.  If
    # the hoard directory does not exist, and we are not creating the
    # hoard, this method is a noop.
    #
    def ready
      if creating?
        create
        @after_create.call
      elsif hoard_exist?
        use
      end
    end

    #
    # Create the hoard.
    #
    # Usually called by #ready, rather than invoked directly.
    #
    def create
      Dir.mkdir(hoard_path)
    end

    #
    # Use the hoard.
    #
    # This sets the load path to the hoard directory.  Usually called
    # by #ready, rather than invoked directly.
    #
    def use
      load_path.replace([hoard_path])
    end

    #
    # Return whether or not we should create the hoard.
    #
    def creating?
      @creating
    end

    #
    # Set whether or not we should create the hoard.
    #
    def create=(value)
      @creating = value
    end

    private # --------------------------------------------------------

    def hoard_exist?
      File.exist?(hoard_path)
    end
  end
end
