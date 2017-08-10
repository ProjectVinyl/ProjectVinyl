require 'projectvinyl/bbc/bbcode'

module ApplicationHelper
  
  def self.read_only
    false
  end
  
  def self.emoticons
    ProjectVinyl::Bbc::Emoticons.all
  end
  
  def emoticons
    ApplicationHelper.emoticons
  end
  
  def self.emotify(text)
    if text.blank?
      return ""
    end
    
    ProjectVinyl::Bbc::Bbcode.from_bbc(text).outer_html
  end
  
  def self.demotify(text)
    if text.blank?
      return ""
    end
    
    ProjectVinyl::Bbc::Bbcode.from_html(text).outer_bbc
  end
  
  def demotify(text)
    ApplicationHelper.demotify(text)
  end
  
  def since(date)
    "#{time_ago_in_words date} ago"
  end
  
  def duration(length)
    if length == 0
      return '--:--'
    end
    length = length.to_f
    hours = 0
    if length >= 3600
      hours = (length / 3600).floor.to_i
      length = length % 3600
    end
    minutes = 0
    if length >= 60
      minutes = (length / 60).floor.to_i
      length = length % 60
    end
    seconds = length.to_i
    if seconds < 10
      seconds = '0' + seconds.to_s
    end
    if minutes < 10
      minutes = '0' + minutes.to_s
    end
    if hours == 0
      return minutes.to_s + ':' + seconds.to_s
    end
    if hours < 10
      hours = '0' + hours.to_s 
    end
    
    hours.to_s + ':' + minutes.to_s + ':' + seconds.to_s
  end
  
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
  
  def title(page_title)
    content_for(:title) { page_title }
  end
  
  def lim(page_width)
    content_for(:width) { page_width }
  end
  
  def wrapper(wrapper_class)
    content_for(:wrapper) { wrapper_class }
  end
  
  def query
    @query || params[:tagquery]
  end
  
  def search_type
    (params[:type] || 0).to_i || 0
  end
  
  def load_time
    Time.now - @start_time
  end
  
  def self.check_and_trunk(str, defa)
    if !str || (str = str.strip).empty?
      return defa
    end
    return str[0, 250] if str.length > 250
    str
  end
  
  def self.valid_string?(s)
    s.present?
  end
  
  def valid_string?(s)
    ApplicationHelper.valid_string?(s)
  end
  
  def safe_to_display(num, max)
    num ||= 0
    if num > max
      return number_with_delimiter(max) + '+'
    end
    number_with_delimiter num
  end
  
  def email_escape(email)
    html_escape(email).gsub(/@/, '<i class="fa fa-at"></i>').html_safe
  end
end
