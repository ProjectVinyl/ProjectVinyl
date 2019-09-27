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

        @parent = path.split('/')

        @full = path

        @path = path.sub('public/', '').sub('private/', '')

        @raw_items = items.reject { |i| i.index('.') == 0 }.group_by { |i| i.index('.').nil? }
        @raw_items = (@raw_items[true] || []) + (@raw_items[false] || []).sort_by { |i| i.split('.')[0] }
      end

      def parent
        result = @parent.map {|p| { path: [], last: false }}

        @parent.each_with_index do |item, index|
          i = @parent.length - 1
          result[index][:name] = item

          while i >= index
            result[i][:path] << item
            i -= 1
          end
        end

        if !result.empty?
          result.last[:last] = true
        end

        result
      end

      def path
        !@path.empty? ? '/' + @path : ''
      end

      def full_path
        @full
      end

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
          @resolver.call(@names, @names_arr, @parent)
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

      def start_from(filename, offset)
        index = @raw_items.index(filename)
        if index
          index += (offset || '0').to_i
          
          if index < 0
            return false
          end

          @raw_items.shift(index + 1)
        else
          return false
        end

        self
      end

      def end_with(filename)
        index = @raw_items.index(filename)
        if index
          @raw_items = @raw_items.shift(index)
          while @limit && @limit > 0 && @raw_items.length > @limit
            @raw_items.shift(@limit)
          end
          @limit = -1
        else
          return false
        end
        self
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

          if @limit && @limit > -1 && @items.length >= @limit
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
