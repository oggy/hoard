module Hoard
  class Base
    class Builder
      def initialize(hoard_path)
        @hoard_path = hoard_path
        @layers = []
        FileUtils.mkdir_p hoard_path
      end

      attr_reader :hoard_path

      def build(load_path)
        load_path.each do |entry|
          add_load_path_entry File.expand_path(entry)
        end
      end

      private  # -----------------------------------------------------

      def layer(number)
        @layers[number] ||= Layer.new(hoard_path, number)
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
        layer.add(path, target)
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
    end
  end
end
