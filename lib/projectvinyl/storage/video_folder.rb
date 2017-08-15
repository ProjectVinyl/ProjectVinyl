module ProjectVinyl
  module Storage
    class VideoFolder
      def initialize(parent, item)
        @parent = parent
        @raw = item
      end

      def each
      end

      def link
        "/admin/files?p=#{@parent.full_path}#{@raw}"
      end

      def stack_size
        -1
      end

      def directory?
        true
      end

      def commit
        @parent.items << self
      end

      def name
        @raw
      end

      def special_name
        ''
      end

      def type
        'Folder'
      end

      def ref
        @raw
      end

      def icon
        "folder-o"
      end
    end
  end
end
