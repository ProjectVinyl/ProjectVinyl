require 'projectvinyl/storage/base_video_file'

module ProjectVinyl
  module Storage
    class VideoFolder < BaseVideoFile
      def initialize(parent, item)
        @parent = parent
        self.raw = item
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

      def name
        @raw
      end

      def type
        'Folder'
      end

      def icon
        "folder-o"
      end
    end
  end
end
