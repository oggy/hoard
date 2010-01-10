module Hoard
  class Base
    class Builder
      def initialize(hoard_path, support_files, options={})
        @hoard_path = hoard_path
        @support_files = support_files
        @layers = []
        @needy_files_optional = options[:needy_files_optional] || false
        FileUtils.mkdir_p hoard_path
      end

      attr_reader :hoard_path, :support_files, :needy_files_optional

      def build(load_path)
        load_path.each do |entry|
          add_load_path_entry File.expand_path(entry)
        end
        support_files.each do |directory, support_spec|
          support_spec.each do |needy_path, support_paths|
            Array(support_paths).each do |support_path|
              layer = layer_with_file(needy_path, directory) or
                needy_files_optional ? next : raise("needy file not found: #{needy_path}")
              num_ascents = num_ascents_required_for(needy_path, support_path) or
                next
              layer.depth = num_ascents

              # TODO: support colliding support paths
              needy_link = Pathname( layer.path_of(needy_path) )
              needy_target = Pathname( layer.target_of(needy_path) )
              support_link = (needy_link.dirname + support_path).cleanpath.to_s
              support_target = (needy_target.dirname + support_path).cleanpath.to_s

              File.exist?(support_target) or
                raise "support file not found: #{support_target}"
              FileUtils.mkdir_p File.dirname(support_link)
              File.symlink(support_target, support_link)
            end
          end
        end
        add_metadata_file
      end

      private  # -----------------------------------------------------

      def layer(number)
        @layers[number-1] ||= Layer.new(hoard_path, number)
      end

      def next_layer(layer)
        layer(layer.number + 1)
      end

      #
      # Add +directory+ to the hoard.
      #
      # If +directory+ is not a directory, don't do anything.
      #
      def add_load_path_entry(directory)
        File.directory?(directory) or
          return
        Dir.foreach(directory) do |entry|
          next if entry =~ /\A\.\.?\z/
          target = File.join(directory, entry)
          add_path(target, entry)
        end
      end

      def add_path(target, path, layer=layer(1))
        while layer.blocked?(path)
          layer = next_layer(layer)
        end
        layer.add(path, target) do |colliding_path, colliding_target|
          if layer.directory?(colliding_path)
            resolve_directory_file_collision(layer, colliding_path, colliding_target)
          elsif File.directory?(colliding_target)
            resolve_file_directory_collision(layer, colliding_path, colliding_target)
          else
            # file/file collision - existing file shadows us.
          end
        end
      end

      def resolve_directory_file_collision(layer, path, target)
        begin
          layer = next_layer(layer)
        end while layer.directory?(path)
        layer.add(path, target) do |colliding_path, colliding_target|
          layer.file?(colliding_path) or
            raise "bug: invariant busted"
          # file/file collision - drop it
        end
      end

      def resolve_file_directory_collision(layer, path, target)
        move_down_a_layer(layer, path)
        layer.add(path, target)
      end

      def move_down_a_layer(layer, path)
        next_layer = next_layer(layer)
        src_path = layer.path_of(path)
        dst_path = next_layer.path_of(path)
        if File.exist?(dst_path)
          move_down_a_layer(next_layer, path)
        elsif (blocking_path = next_layer.blocking_path(path))
          move_down_a_layer(next_layer, blocking_path)
          FileUtils.mkdir_p File.dirname(dst_path)
        else
          FileUtils.mkdir_p File.dirname(dst_path)
        end
        File.rename(src_path, dst_path)
      end

      def layer_with_file(path, directory)
        @layers.find do |layer|
          target = File.expand_path( File.join(directory, path) )
          layer.target_of(path) == target
        end
      end

      #
      # Return the number of ascents required for +support path+
      # relative to +needy_path+.
      #
      # This is the number of directories ascended through above the
      # root of the layer, when walking to +support_path+ from
      # +needy_path+.
      #
      # For example, if 'a/b/c' needs support path '../../../../file',
      # then the number of ascents is 2, as the path relative to the
      # root of the layer is '../../file'.
      #
      # If the support_path does not ascend past the root of the
      # layer, return nil.  In this case, no support file is needed,
      # as the file should be in the same load path directory as the
      # file.
      #
      def num_ascents_required_for(needy_path, support_path)
        pathname = Pathname(support_path)
        pathname.relative? or
          raise ArgumentError, "support file must be a relative path (to the needy file)"
        num_support_ascents = "#{pathname.cleanpath}/".scan(/\.\.\//).size
        num_needy_ascents = Pathname(needy_path).cleanpath.to_s.split(File::SEPARATOR).size - 1
        num_support_ascents - num_needy_ascents
      end

      def add_metadata_file
        directories = @layers.map do |layer|
          layer.path_from_hoard
        end
        data = {'load_path' => directories}
        open File.join(hoard_path, 'metadata.yml'), 'w' do |file|
          file.puts data.to_yaml
        end
      end
    end
  end
end
