require 'hoard/base/builder'
require 'hoard/base/layer'

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
    #  * :support_files - TODO
    #
    # Unless creating the hoard, the load path will be replaced with
    # the hoard directory, and modifications to it will be disabled
    # until the #ready call.
    #
    def initialize(options={})
      @hoard_path = options[:hoard_path] || 'hoard'
      @creating = options[:create] || false
      @support_files = options[:support_files] || {}

      @load_path = options[:load_path] || $LOAD_PATH
      @after_create = options[:after_create] || lambda{exit}

      use if !creating? && hoard_exist?
    end

    #
    # The path of the hoard directory.
    #
    attr_accessor :hoard_path

    #
    # The support files to add to the hoard.
    #
    attr_accessor :support_files

    #
    # The load path array that will be modified when the hoard is
    # #use-d.
    #
    attr_accessor :load_path

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
        unstub_load_path_modifications
      end
    end

    #
    # Create the hoard.
    #
    # Usually called by #ready, rather than invoked directly.
    #
    def create
      builder = Builder.new(hoard_path, support_files)
      builder.build(load_path)
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

    #
    # Set the load path to the hoard layers, and stub out
    # modifications to it until #ready is called.
    #
    def use
      metadata_path = "#{hoard_path}/metadata.yml"
      directories = YAML.load_file(metadata_path)['load_path']
      directories.map!{|dir| './' + File.join(hoard_path, dir)}
      load_path.replace(directories)
      stub_load_path_modifications
    end

    def hoard_exist?
      File.file?("#{hoard_path}/metadata.yml")
    end

    DESTRUCTIVE_ARRAY_METHODS = %w'
      << []= clear collect! compact! concat delete delete_at delete_if
      fill flatten! insert map! pop push reject! replace reverse!
      shift shuffle! slice! sort! uniq! unshift
    '

    def stub_load_path_modifications
      @load_path.extend load_path_protector
    end

    def unstub_load_path_modifications
      DESTRUCTIVE_ARRAY_METHODS.each do |name|
        @load_path_protector.send(:remove_method, name)
      end
    end

    def load_path_protector
      @load_path_protector ||= Module.new do
        source = DESTRUCTIVE_ARRAY_METHODS.map do |name|
          "def #{name}(*args) end;"
        end.join
        class_eval source
      end
    end
  end
end
