module WithFiles
  extend ActiveSupport::Concern

  def self.storage_path(date)
    [date.year.to_s, date.month.to_s, date.day.to_s].join('/')
  end
  
  def storage_path
    [WithFiles.storage_path(created_at), id].join('/')
  end
  
  def storage_root
    self.hidden ? 'private' : 'public'
  end
  
  def del_file(path)
    File.delete(path) if has_file(path)
  end
  
  def rename_file(from, to)
    if has_file(from)
      FileUtils.mkdir_p(File.dirname(to))
      FileUtils.mv(from, to)
    end
  end
  
  def has_file(path)
    File.exist?(path)
  end
  
  def file_link(path, name)
    "/admin/files?p=#{path}&start=#{name}&offset=-5##{self.id}"
  end
  
  def save_file(path, uploaded_io, type)
    del_file(path)
    if !uploaded_io || uploaded_io == true || !uploaded_io.content_type.include?(type)
      return false
    end
    
    store_file(path, uploaded_io.read)
    
    if block_given?
      yield
    end
    
    true
  end

  def store_file(path, data)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'wb') do |file|
      file.write(data)
      file.flush
    end
  end
end
