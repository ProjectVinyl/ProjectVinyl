require 'projectvinyl/storage/video_folder'

module ProjectVinyl
  module Storage
    class VideoFile < BaseVideoFile
      def self.directory?(parent, item)
        File.directory?(Rails.root.join(parent.full_path, item).to_s)
      end

      def self.create(parent, item)
        return VideoFolder.new(parent, item) if VideoFile.directory?(parent, item)
        VideoFile.new(parent, item)
      end

      def initialize(parent, item)
        @parent = parent
        self.raw = item
      end

      def directory?
        false
      end

      attr_reader :type
      attr_reader :name

      def link
        @parent.path + @name + '.' + @type
      end

      def icon
        return 'picture-o' if @type == 'png'
        return 'file-video-o' if @type == 'webm'
        if mime = Mimes.mime('.' + @type)
          return 'file-image-o' if mime.index('image/') == 0
          return 'film' if mime.index('video/') == 0
          return 'volume-up' if mime.index('audio/') == 0
          if mime.index('zip') || mime.index('compressed') || mime.index('octet')
            return 'file-archive-o'
          end
          return 'file-word-o' if mime.index('document')
          return 'file-pdf-o' if mime.index('/pdf')
        end
        'file-o'
      end

      protected

      def raw=(item)
        super(item)
        item = item.split('.')
        if item.length == 1
          @type = 'file'
          @name = item[0]
        else
          @type = item.pop
          @name = item.join('.')
        end
      end
    end
  end
end
