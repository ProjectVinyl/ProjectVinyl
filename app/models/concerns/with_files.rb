module WithFiles
  extend ActiveSupport::Concern

  included do
    before_destroy :remove_assets
  end

  def update_file_locations
    if hidden
      return move_assets('public', 'private')
    end

    move_assets('private', 'public')
  end

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
    "/admin/files?p=#{path}&start=#{name}##{name}"
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

  def file_path(filename, root = nil)
    Rails.root.join(root || storage_root, model_path, storage_path, filename)
  end

  def public_url(filename)
    ['', model_path, storage_path, filename].join('/')
  end

  protected

  def remove_assets
  end

  def move_assets(from, to)
  end

  def model_path
    ''
  end
end
