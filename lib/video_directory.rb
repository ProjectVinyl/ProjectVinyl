class VideoFolder
  def initialize(parent, item)
    @parent = parent
    @raw = item
  end
  
  def each
    
  end
  
  def link
    return '/admin/files?p=' + @parent.full_path + @raw
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

class VideoFile
  def self.directory?(item)
    item.index('.').nil?
  end
  
  def self.create(parent, item)
    if VideoFile.directory?(item)
      return VideoFolder.new(parent, item)
    end
    VideoFile.new(parent, item)
  end
  
  def initialize(parent, item)
    @parent = parent
    self.raw = item
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
      if !@entries
        @entries = []
      end
      created = VideoFile.new(@parent, item)
      @entries << created
      if item.length < @raw.length
        created.raw = @raw
        self.raw = item
      end
    end
  end
  
  def directory?
    false
  end
  
  def commit
    @saved = true
    @parent.items << self
  end
  
  def type
    @type
  end
  
  def name
    @name
  end
  
  def special_name
    if @parent.names.key?(@key)
      return @parent.names[@key]
    end
    nil
  end
  
  def link
    return @parent.path + @name + '.' + @type
  end
  
  def ref
    @raw
  end
  
  def icon
    if @type == 'png'
      return 'picture-o'
    end
    if @type == 'webm'
      return 'file-video-o'
    end
    mime = Mimes.mime('.' + @type)
    if mime.index('image/') == 0
      return 'file-image-o'
    end
    if mime.index('video/') == 0
      return 'film'
    end
    if mime.index('audio/') == 0
      return 'volume-up'
    end
    if mime.index('zip') || mime.index('compressed') || mime.index('octet')
      return 'file-archive-o'
    end
    if mime.index('document')
      return 'file-word-o'
    end
    if mime.index('/pdf')
      return 'file-pdf-o'
    end
    return 'file-o'
  end
  
  protected
  def raw=(item)
    @raw = item
    @key = item.split(/\.|-/)[0]
    item = item.split('.')
    @type = item.pop
    @name = item.join('.')
  end
end

class VideoDirectory
  def self.Entries(path)
    VideoDirectory.new(path, Dir.entries(Rails.root.join(path).to_s))
  end
  
  def initialize(path, items)
    if path.last != '/'
      path += '/'
    end
    @parent = path.split('/')
    @full = path
    @path = path.sub('public/', '')
    @raw_items = items.reject {|i| i.index('.') == 0 }.group_by do |i|
      i.index('.').nil?
    end
    @raw_items = (@raw_items[true] || []) + (@raw_items[false] || []).sort_by {|i| i.split('.')[0].to_i}
  end
  
  def parent
    result = []
    while result.length < @parent.length
      result << {path: [], last: false}
    end
    @parent.each_with_index do |item,index|
      i = @parent.length - 1
      result[index][:name] = item
      while i >= index
        result[i][:path] << item
        i -= 1
      end
    end
    if result.length > 0
      result.last[:last] = true
    end
    return result
  end
  
  def path
    @path.length > 0 ? '/' + @path : ''
  end
  
  def full_path
    @full
  end
  
  def items
    if !@items
      gen
    end
    return @items
  end
  
  def names
    if !@items
      gen
    end
    if !@resolved
      @resolved = true
      if @resolver
        @resolver.call(@names, @names_arr)
      end
    end
    return @names
  end
  
  def filter(&block)
    @filter = block
    return self
  end
  
  def names_resolver(&block)
    @resolver = block
    return self
  end
  
  def offset(o)
    @offset = o
    return self
  end
  
  def limit(l)
    @limit = l
    return self
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
    return self
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
    return self
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
      break if @limit && @limit > -1 && @items.length >= @limit
      if i.index('.') != 0
        key = i.split(/\.|-/)[0]
        if !@names.key?(key) || VideoFile.directory?(i)
          @names[key] = key
          if !@filter || @filter.call(i)
            if @offset && @offset > 0
              @offset -= 1
              next
            end
            data[key] = VideoFile.create(self, i)
            if !data[key].directory?
              @names_arr << key
            end
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