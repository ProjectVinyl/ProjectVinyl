module WithFiles
  extend ActiveSupport::Concern

  included do
    before_destroy :remove_assets if respond_to? :before_destroy
    @asset_groups = {}
    def self.__asset_groups
      @asset_groups
    end

    def self.asset_root(path)
      define_method :asset_root do
        path.to_s
      end
    end

    def self.has_asset(asset_name, file_name, params = {}, &getter)
      is_method = :a.is_a?(file_name.class)

      path_method_sym = "#{asset_name}_path".to_sym
      url_method_sym = "#{asset_name}_url".to_sym
      file_link_sym = "#{asset_name}_file_link".to_sym

      define_method path_method_sym do |root=nil|
        Rails.root.join(root || storage_root, asset_root, storage_path, is_method ? self.send(file_name, asset_name) : file_name)
      end
      define_method url_method_sym do
        ["/#{asset_root}", storage_path, is_method ? self.send(file_name, asset_name) : file_name].join('/')
      end
      define_method "has_#{asset_name}?".to_sym do
        File.exist?(send(path_method_sym))
      end
      define_method file_link_sym do
        name = is_method ? self.send(file_name, asset_name) : file_name
        "/admin/files?p=#{[storage_root, asset_root, storage_path].join('/')}&start=#{name}##{name}"
      end

      if !getter.nil?
        define_method asset_name, &getter
      elsif params[:cache_bust]
        def_accessor = params[:cache_bust].is_a?(Symbol) ? params[:cache_bust] : asset_name
        define_method def_accessor do cache_bust(send(url_method_sym)) end
      end
      
      asset_syms = {
        name: file_name.to_s,
        path: path_method_sym,
        url: url_method_sym,
        link: file_link_sym
      }

      groups = params[:group] || :all
      groups = [groups] if :a.is_a?(groups.class)
      groups.each do |group|
        if !__asset_groups.key?(group)
          __asset_groups[group] = []

          if group != :all
            define_method "remove_#{group}".to_sym do
              each_asset(group) {|f| del_file(send(f)) }
            end
          end
        end

        __asset_groups[group] << asset_syms
      end
    end
  end

  def update_file_locations
    change = (respond_to?(:hidden) && hidden) ? ['public', 'private'] : ['private', 'public']

    from, to = change.map {|r| [r, asset_root, storage_path].join('/')}

    FileUtils.mkdir_p(to)
    if File.exist?(from)
      Dir.entries(from).filter{|d| d[0] != '.'}.each do |file|
        FileUtils.mv([from, file].join('/'), [to, file].join('/'))
      end
      Dir.delete(from)
    end
  end

  def self.storage_path(date)
    (date || DateTime.now).strftime("%Y/%-m/%-d")
  end

  def storage_path
    [WithFiles.storage_path(created_at), id].join('/')
  end

  def storage_root
    (respond_to?(:hidden) && hidden) ? 'private' : 'public'
  end

  def del_file(path)
    FileUtils.remove_entry(path) if File.exist?(path)
  end

  def save_file(path, uploaded_io, type)
    del_file(path)
    return false if !uploaded_io || uploaded_io == true || !uploaded_io.content_type.include?(type)

    store_file(path, uploaded_io.read)

    yield if block_given?
    true
  end

  def store_file(path, data)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'wb') do |file|
      file.write(data)
      file.flush
    end
  end
  
  def assets(*groups)
    entries = self.class.__asset_groups
    groups = entries.keys if groups.include?(:all)
    groups
      .flat_map{|g| entries[g] || []}
      .uniq
      .map{|syms| Asset.new(self, syms)}
  end

  protected
  def each_asset(*groups, &block)
    entries = self.class.__asset_groups
    groups = entries.keys if groups.include?(:all)
    groups
      .flat_map{|g| entries[g] || []}
      .uniq
      .each &block
  end

  def remove_assets
    each_asset(:all) {|f| del_file(send(f[:path])) }
  end
  
  class Asset
    attr_reader :name
    
    def initialize(owner, method_syms)
      @name = method_syms[:name]
      @owner = owner
      @method_syms = method_syms
    end
    
    def path
      @owner.send(@method_syms[:path])
    end
    
    def url
      @owner.send(@method_syms[:url])
    end
    
    def link
      @owner.send(@method_syms[:link])
    end
    
    def size
      return 0 if !path.exist?
      return path.size?.to_f / 2**20 if !path.directory?
      path.children
        .map{|f| f.size?.to_f / 2**20}
        .sum 
    end
    
    def ext
      path.extname.sub('.', '')
    end
  end
end
