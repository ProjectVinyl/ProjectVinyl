require 'projectvinyl/storage/video_file'

module ProjectVinyl
  module Storage
    class VideoDirectory
      def self.entries(path)
        VideoDirectory.new(path, Dir.entries(Rails.root.join(path).to_s))
      end

      def initialize(path, items)
        if path.last != '/'
          path += '/'
        end

        limit(-1)

        @parents = path.split('/')

        @full_path = path

        @path = path.sub('public/', '').sub('private/', '')

        @raw_items = items.reject { |i| i.index('.') == 0 }.group_by { |i| i.index('.').nil? }
        @raw_items = (@raw_items[true] || []) + (@raw_items[false] || []).sort_by { |i| i.split('.')[0] }
      end

      def parent
        @parents.each_with_index.map do |item, index|
          {
            name: item,
            path: @parents[index..(@parents.length - 1)],
            last: index == (@parents.length - 1)
          }
        end
      end

      def path
        !@path.empty? ? '/' + @path : ''
      end

      attr_reader :full_path

      def items
        gen if !@items
        @items
      end

      def names
        if !@items
          gen
        end

        if @resolver && !@resolved
          @resolved = true
          @resolver.call(@names, @names_arr, @parents)
        end

        @names
      end

      def filter(&block)
        @filter = block

        self
      end

      def names_resolver(&block)
        @resolver = block

        self
      end

      def offset(o)
        @offset = o

        self
      end

      def limit(l)
        @limit = l

        self
      end

      def buffer_before(filename, offset)

        stop = @raw_items.index(filename)

        if !stop || stop == 0
          return false
        end

        stop = [stop + 1,(@raw_items.length - 1)].min
        start = stop - ((offset.nil? ? @limit : offset.to_i) | 0)
        start = [start,0].max

        buffer_range(start, stop)
      end

      def buffer_after(filename, offset)

        start = @raw_items.index(filename)

        if !start
          return false
        end

        start = start + 1

        stop = start + ((offset.nil? ? @limit : offset.to_i) | 0)
        stop = [stop, @raw_items.length].min

        buffer_range(start, stop)
      end

      def buffer_range(start, stop)
        lower = [stop,start].min
        upper = [stop,start].max

        @raw_items = @raw_items[lower..@raw_items.length]

        if (upper - lower) == 0
          return false
        end

        limit(upper - lower)
      end

      def start_ref
        if @raw_items.length
          return @raw_items.first
        end

        nil
      end

      def end_ref
        if !@end
          gen
        end

        @end
      end

      private

      def gen
        @end = ""
        @items = []
        data = {}
        @names_arr = []
        @names = {}

        @raw_items.each do |i|

          if @limit && @items.length >= @limit
            break
          end

          key = i.split(/\.|-/)[0]

          if !@names.key?(key) || VideoFile.directory?(self, i)
            @names[key] = key

            if !@filter || @filter.call(i)
              if @offset && @offset > 0
                @offset -= 1
                next
              end

              data[key] = VideoFile.create(self, i)

              @names_arr << key

              data[key].commit
              @end = i
            end

          elsif data.key?(key)
            data[key].consume(i)
            @end = i
          end
        end
      end
    end
  end
end
