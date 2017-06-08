class VideoFolder
  def initialize(parent, item)
    @parent = parent
    @raw = item
  end

  def each
  end

  def link
    '/admin/files?p=' + @parent.full_path + @raw
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

  def directory?
    false
  end

  def commit
    @saved = true
    @parent.items << self
  end

  attr_reader :type

  attr_reader :name

  def special_name
    return @parent.names[@key] if @parent.names.key?(@key)
    nil
  end

  def link
    @parent.path + @name + '.' + @type
  end

  def ref
    @raw
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
    @raw = item
    @key = item.split(/\.|-/)[0]
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

class VideoDirectory
  def self.Entries(path)
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
