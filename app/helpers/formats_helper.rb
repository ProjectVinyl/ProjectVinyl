module FormatsHelper

  def since(date)
    "#{time_ago_in_words date} ago"
  end
  
  def in_time_zone(date)
    return date if date.nil?
    date.in_time_zone
  end
  
  def fuzzy_big_number_with_delimiter(number)
    number_to_human(number, {
      precision: 2,
      significant: false,
      delimiter: ',',
      units: {
        thousand: 'K',
        million: 'M',
        billion: 'B',
        trillion: 'T',
        quadrillion: 'Q'
      }
    })
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
