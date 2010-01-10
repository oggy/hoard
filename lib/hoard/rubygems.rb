module Hoard
  class Rubygems < Base
    #
    # Use this hoard if Rubygems is being used.
    #
    # Adds the following options:
    #
    #  * gem_support_files: specifies support files that are required
    #    to exist relative to files in the gem require path(s).  See
    #    #gem_support_files for details.
    #
    def initialize(options={})
      super
      @gem_support_files = options[:gem_support_files] || {}
      @source_index = options[:source_index] || Gem.source_index
    end

    #
    # The gem support files to add to the hoard.
    #
    # This is a nested hash of the following format (example is valid
    # YAML):
    #
    #     gem-name:
    #       require-path:
    #         needy-file-1: support-file-1
    #         ...
    #
    # Each placeholder above can occur in any multiplicity: there can
    # be multple gems, each gem can contain multiple require paths,
    # and each require path can contain multiple needy files.
    #
    attr_accessor :gem_support_files

    #
    # The gem source index to look for specifications in.
    #
    # (Primarily used for testing.)
    #
    attr_accessor :source_index

    #
    # Overrides Base.
    #
    def create
      add_gem_support_files
      super
    end

    private  # -------------------------------------------------------

    def add_gem_support_files
      gem_support_files.each do |gem, require_paths|
        specification = specification_for(gem) or
          needy_files_optional ? next : raise("gem not loaded: #{gem}")
        full_gem_path = Pathname(specification.full_gem_path).cleanpath.to_s
        require_paths.each do |require_path, needy_paths|
          full_require_path = "#{full_gem_path}/#{require_path}"
          support_files[full_require_path] = {}
          needy_paths.each do |needy_path, support_path|
            support_files[full_require_path][needy_path] = support_path
          end
        end
      end
    end

    def specification_for(name)
      # TODO: support version-specific gem support files
      requirements = Gem::Requirement.default
      dependency = Gem::Dependency.new(name, requirements)
      source_index.search(dependency).first
    end
  end
end
