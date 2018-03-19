module WithFiles
  extend ActiveSupport::Concern
  
  def storage_root
    self.hidden ? 'private' : 'public'
  end
  
  def del_file(path)
    File.delete(path) if File.exist?(path)
  end
  
  def rename_file(from, to)
    if File.exist?(from)
      FileUtils.mv(from, to)
    end
  end
  
  def file_link(path, name)
    "/admin/files?p=#{path}&start=#{name}%offset=-5##{self.id}"
  end
  
  def img(path, uploaded_io)
    if uploaded_io
      File.open(path, 'wb') do |file|
        file.write(uploaded_io.read)
        return true
      end
    end
    false
  end
end
