module PathHelper
  def selected_path?(type)
    if !@path_type
      @path_type = request.path.split('/')[1]
      if @path_type == 'thread'
        @path_type = 'forum'
      end
    end
    @path_type == type ? ' selected' : ''
  end
  
  def self.url_safe(txt)
    txt.gsub(/(\/|[^:\!\@\$\^&\*\(\)\+=_;:'",a-zA-Z0-9\-])+/, '-').gsub(/--/, '-').gsub(/(^-)|(-$)/, '')
  end
  
  def self.url_safe_for_tags(txt)
    txt.gsub(/(\/|[^:\!\@\$\^&\*\(\)\+=_;:'",a-zA-Z0-9 \-])+/, '-').gsub(/--/, '-').gsub(/(^-)|(-$)/, '')
  end
  
  def load_time
    Time.now - @start_time
  end
end
