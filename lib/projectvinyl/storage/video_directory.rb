require 'projectvinyl/storage/video_file'

module ProjectVinyl
  module Storage
    class VideoDirectory
      def self.entries(path)
        VideoDirectory.new(path, Dir.entries(Rails.root.join(path).to_s))
      end

      def initialize(path, items)
        path += '/' if path.last != '/'
        @parent = path.split('/')
        @full = path
        @path = path.sub('public/', '').sub('private/', '')
        @raw_items = items.reject { |i| i.index('.') == 0 }.group_by do |i|
          i.index('.').nil?
        end
        @raw_items = (@raw_items[true] || []) + (@raw_items[false] || []).sort_by { |i| i.split('.')[0].to_i }
      end

      def parent
        result = []
        result << { path: [], last: false } while result.length < @parent.length
        @parent.each_with_index do |item, index|
          i = @parent.length - 1
          result[index][:name] = item
          while i >= index
            result[i][:path] << item
            i -= 1
          end
        end
        result.last[:last] = true if !result.empty?
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
        gen if !@items
        if !@resolved
          @resolved = true
          @resolver.call(@names, @names_arr) if @resolver
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
          return false if index < 0
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
        return @raw_items.first if @raw_items.length
        nil
      end

      def end_ref
        gen if !@end
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
          break if @limit && @limit > -1 && @items.length >= @limit
          next unless i.index('.') != 0
          key = i.split(/\.|-/)[0]
          if !@names.key?(key) || VideoFile.directory?(self, i)
            @names[key] = key
            if !@filter || @filter.call(i)
              if @offset && @offset > 0
                @offset -= 1
                next
              end
              data[key] = VideoFile.create(self, i)
              @names_arr << key if !data[key].directory?
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
