module PathHelper
  def selected_path?(type)
    if !@path_type
      @path_type = request.path.split('/')[1]
      if @path_type == 'threads'
        @path_type = 'forum'
      end
    end
    @path_type == type ? ' selected' : ''
  end

  def self.clean_url(s)
    return '' if s.blank?
    return "https:#{s}" if s.index('http:') != 0 && s.index('https:') != 0
    s
  end

  def self.url_safe(txt)
    return txt if txt.blank?
    txt.gsub(/(\/|[^:\!\@\$\^&\*\(\)\+=_;:'",a-zA-Z0-9\-])+/, '-').gsub(/--/, '-').gsub(/(^-)|(-$)/, '')
  end

  def self.url_safe_for_tags(txt)
    return txt if txt.blank?
    txt.gsub(/(\/|[^:\!\@\$\^&\*\(\)\+=_;:'",a-zA-Z0-9 \-])+/, '-').gsub(/--/, '-').gsub(/(^-)|(-$)/, '')
  end

  def load_time
    Time.now - @start_time
  end


  def self.absolute_url(url, root)
    if url[0] == '/'
      url = url.gsub(/^\//,'')
    end
    "#{root}#{url}"
  end

  def absolute_url(url, root = nil)
    PathHelper.absolute_url(url, root_url)
  end
end
