module WithFiles
  extend ActiveSupport::Concern
  
  def storage_root
    self.hidden ? 'private' : 'public'
  end
  
  def del_file(path)
    File.delete(path) if has_file(path)
  end
  
  def rename_file(from, to)
    if has_file(from)
      FileUtils.mv(from, to)
    end
  end
  
  def has_file(path)
    File.exist?(path)
  end
  
  def file_link(path, name)
    "/admin/files?p=#{path}&start=#{name}%offset=-5##{self.id}"
  end
  
  def save_file(path, uploaded_io, type)
    del_file(path)
    if !uploaded_io || uploaded_io == true || !uploaded_io.content_type.include?(type)
      return false
    end
    
    File.open(path, 'wb') do |file|
      file.write(uploaded_io.read)
      file.flush
    end
    
    if block_given?
      yield
    end
    
    true
  end
end
