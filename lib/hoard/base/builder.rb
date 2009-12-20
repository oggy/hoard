module Hoard
  class Base
    class Builder
      def initialize(hoard_path)
        @hoard_path = hoard_path
        FileUtils.mkdir_p hoard_path
      end

      attr_reader :hoard_path

      #
      # Add +directory+ to the hoard.
      #
      # If +directory+ is not a directory, don't do anything.
      #
      def add_load_path_entry(directory)
        File.directory?(directory) or
          return
        each_directory_entry(directory) do |entry|
          target = File.join(directory, entry)
          add_path(target, entry)
        end
      end

      #
      # Add a link to +target+ at the +path+ in the hoard.
      #
      def add_path(target, path, layer=1)
        while blocking_path(layer, path)
          layer += 1
        end
        add_to_layer(layer, target, path)
      end

      #
      # Return the path of the file that blocks +path+ being added to
      # +layer+, if any.  The returned path is relative to the layer.
      #
      # A file blocks a path if it is not a directory, and is a proper
      # prefix of the path.  e.g., a file "/a/b" blocks "/a/b/c".  A
      # file does not block its own path.
      #
      def blocking_path(layer, path)
        current_path = File.join(hoard_path, layer.to_s)
        relative_path = '.'
        File.dirname(path).split(File::SEPARATOR).each do |segment|
          relative_path = File.join(relative_path, segment)
          current_path = File.join(current_path, segment)
          return relative_path if File.file?(current_path)
        end
        nil
      end

      #
      # Add a symlink to the +target+ at +path+ in +layer+.
      #
      # Return false if the link cannot go in this layer, and the next
      # layer should be tried, false otherwise.
      #
      def add_to_layer(layer, target, path)
        link_path = File.join(hoard_path, layer.to_s, path)
        if File.directory?(link_path)
          if File.directory?(target)
            resolve_directory_directory_collision(layer, target, path, link_path)
          else
            resolve_directory_file_collision(layer, target, path, link_path)
          end
        elsif File.exist?(link_path)
          if File.directory?(target)
            resolve_file_directory_collision(layer, target, path, link_path)
          else
            # File/file collision - existing file shadows us.
            true
          end
        else
          FileUtils.mkdir_p File.dirname(link_path)
          File.symlink(target, link_path)
          true
        end
      end

      def resolve_directory_directory_collision(layer, target, path, link_path)
        # If existing directory is a symlink, turn it into a real
        # directory with child symlinks.
        if File.symlink?(link_path)
          prior_target = File.readlink(link_path)
          File.unlink(link_path)
          Dir.mkdir(link_path)
          each_directory_entry(prior_target) do |prior_entry|
            File.symlink(File.join(prior_target, prior_entry),
                         File.join(link_path, prior_entry))
          end
        end

        # Recurse with each child.
        each_directory_entry(target) do |entry|
          child_target = File.join(target, entry)
          child_path = File.join(path, entry)
          add_path(child_target, child_path, layer)
        end
        true
      end

      def resolve_directory_file_collision(layer, target, path, link_path)
        # Find a layer without a directory in the way, and try again.
        begin
          layer += 1
          link_path = File.join(hoard_path, layer.to_s, path)
        end while File.directory?(link_path)
        add_path(target, path, layer)
        true
      end

      def resolve_file_directory_collision(layer, target, path, link_path)
        # Move the file down a layer, and put the directory here.
        move_down_a_layer(layer, path)
        File.symlink(target, link_path)
        true
      end

      def move_down_a_layer(layer, path)
        next_layer = layer + 1
        src_path = File.join(hoard_path, layer.to_s, path)
        dst_path = File.join(hoard_path, next_layer.to_s, path)
        if File.exist?(dst_path)
          move_down_a_layer(next_layer, path)
        elsif (blocking_path = blocking_path(next_layer, path))
          move_down_a_layer(next_layer, blocking_path)
          FileUtils.mkdir_p File.dirname(dst_path)
        else
          FileUtils.mkdir_p File.dirname(dst_path)
        end
        File.rename(src_path, dst_path)
      end

      def each_directory_entry(path)
        Dir.entries(path).each do |entry|
          next if entry =~ /\A\.\.?\z/
          yield entry
        end
      end
    end
  end
end
