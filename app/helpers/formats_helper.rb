module FormatsHelper
  def since(date)
    "#{time_ago_in_words date} ago"
  end
  
  def duration(length)
    if length == 0
      return '--:--'
    end
    
    Ffmpeg.to_h_m_s(length) do |h, m, s|
      if h == 0
        return format("%02d:%02d", m, s)
      end
    end
  end
  
  def safe_to_display(num, max)
    num ||= 0
    if num > max
      return number_with_delimiter(max) + '+'
    end
    number_with_delimiter num
  end
end
