require 'projectvinyl/storage/video_file'

module ProjectVinyl
  module Storage
    class StackableVideoFile < VideoFile
      def initialize(parent, item)
        super(parent, item)
      end

      def stack_size
        @entries ? @entries.length : 0
      end

      def each
        if @entries
          if !@sorted
            @sorted = true
            @entries.sort_by! do |i|
              i.name.length
            end
          end
          @entries.each do |i|
            yield(i)
          end
        end
      end

      def consume(item)
        if @saved
          @entries = [] if !@entries
          created = VideoFile.new(@parent, item)
          @entries << created
          if item.length < @raw.length
            created.raw = @raw
            self.raw = item
          end
        end
      end
    end
  end
end
