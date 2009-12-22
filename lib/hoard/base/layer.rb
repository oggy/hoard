module Hoard
  class Base
    class Layer
      def initialize(hoard_path, number)
        @hoard_path = hoard_path
        @number = number
        @root = File.join(hoard_path, number.to_s)
        @path = @root.dup
        @depth = 0
        FileUtils.mkdir_p path
      end

      #
      # The path of the root of the hoard.
      #
      attr_reader :hoard_path

      #
      # The layer number.
      #
      attr_reader :number

      #
      # The path of the root of the layer.
      #
      attr_reader :root

      #
      # The path of the directory in the layer that is added to the
      # load path when the hoard is used.
      #
      attr_reader :path

      #
      # Same as #path, but relative to the hoard path.
      #
      def path_from_hoard
        Pathname(path).relative_path_from(Pathname(hoard_path)).to_s
      end

      #
      # The number of directories under the layer root at which #path
      # resides.
      #
      # Usually, this is 0.  If support files are required, however,
      # extra directories need to be added above the usual layer path.
      # This is done by pushing the path down using dummy directories.
      # For example, if 'a/b/c' needs a support file
      # '../../../../file', the layer looks like:
      #
      #     .
      #     |-- __hoard__
      #     |   `-- __hoard__
      #     |       `-- a
      #     |           `-- b
      #     |               `-- c
      #     `-- file
      #
      attr_reader :depth

      #
      # Set the depth of the layer.
      #
      # Modify the directory structure as required.
      #
      def depth=(depth)
        return if depth == @depth

        original_depth = @depth
        original_path = @path

        @depth = depth
        @path = depth.zero? ? root : File.join(root, '/__hoard__'*depth)
        if depth > original_depth
          File.rename original_path, "#{original_path}.tmp"
          FileUtils.mkdir_p File.dirname(path)
          File.rename "#{original_path}.tmp", path
        else
          File.rename original_path, "#{path}.tmp"
          FileUtils.rm_rf path
          File.rename "#{path}.tmp", path
        end
      end

      #
      # Return the given path relative to the layer path.
      #
      def path_of(path)
        File.join(self.path, path)
      end

      #
      # Return the target of the symlink at +path+, or nil if no such
      # symlink exists.
      #
      def target_of(path)
        file?(path) or
          return nil
        File.readlink(path_of(path))
      end

      #
      # Return true if the +path+ is a (nondirectory) file in this
      # layer.
      #
      def file?(path)
        File.file?(path_of(path))
      end

      #
      # Return true if the +path+ is a directory in this layer.
      #
      def directory?(path)
        File.directory?(path_of(path))
      end

      #
      # Return true if there is a (nondirectory) file at an ancestor
      # path of +path+.
      #
      def blocked?(path)
        !!blocking_path(path)
      end

      #
      # Add a symlink at +path+ that points to +target+.
      #
      # Assumes that +path+ is not blocked (see #blocked?).  If there
      # are any file collisions as a result of adding the file, each
      # colliding link path and target is yielded.
      #
      def add(path, target, &resolve_collision)
        link_path = path_of(path)
        if File.directory?(link_path) && File.directory?(target)
          merge_directories(path, target, link_path, &resolve_collision)
        elsif !File.exist?(link_path)
          FileUtils.mkdir_p File.dirname(link_path)
          File.symlink target, link_path
          true
        else
          yield path, target
        end
      end

      #
      # Return the path of the file (relative the the layer path) that
      # blocks +path+ being added to this layer, if any.
      #
      # A file blocks a path if it is not a directory, and is a proper
      # prefix of the path.  e.g., a file "/a/b" blocks "/a/b/c".  A
      # file does not block its own path.
      #
      def blocking_path(path)
        current_path = self.path
        relative_path = '.'
        File.dirname(path).split(File::SEPARATOR).each do |segment|
          relative_path = File.join(relative_path, segment)
          current_path = File.join(current_path, segment)
          return relative_path if File.file?(current_path)
        end
        nil
      end

      private  # -----------------------------------------------------

      def merge_directories(path, target, link_path, &resolve_collision)
        if File.symlink?(link_path)
          replace_symlink_with_directory_of_child_links(link_path)
        end

        Dir.foreach(target) do |entry|
          next if entry =~ /\A\.\.?\z/
          child_target = File.join(target, entry)
          child_path = File.join(path, entry)
          add(child_path, child_target, &resolve_collision)
        end
      end

      def replace_symlink_with_directory_of_child_links(link_path)
        prior_target = File.readlink(link_path)
        File.unlink(link_path)
        Dir.mkdir(link_path)
        Dir.foreach(prior_target) do |entry|
          next if entry =~ /\A\.\.?\z/
          File.symlink(File.join(prior_target, entry),
                       File.join(link_path, entry))
        end
      end
    end
  end
end
