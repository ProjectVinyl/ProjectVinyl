module ApplicationHelper
  Emoticons = [ 'pinkiesmile' ]
  def emotify(text)
    text = text.gsub(/\n/,'<br>').gsub(/([buis])\]/, '[\1]').gsub(/\[\/([buis])\]/, '</\1>')
    Emoticons.each { |x|
      text = text.gsub(/:#{x}:/,'<img class="emoticon" src="/emoticons/' + x + '.png">')
    }
    return text
  end

  def demotify(text)
    text = text.gsub(/\<br\>/,'\n').gsub(/\<([buis])\>/, '[\1]').gsub(/\<\/([buis])\>/, '[/\1]')
    Emoticons.each { |x|
      text = text.gsub(/<img class="emoticon" src="\/emoticons\/#{x}">:/,':' + x + ':">')
    }
    return text
  end
  
  def emoticons
    return Emoticons
  end
  
  def since(date)
    date = date.to_f.to_i
    if date >= 60000
      date = (date/60000).floor
      if date >= 60
        date = (date/60).floor
        if date >= 24
          date = (date/24).floor
          if date >= 365
            date = (date/365).floor
            return date.to_s + ' years ago'
          end
          return date.to_s + ' hours ago'
        end
        return date.to_s + ' minutes ago'
      end
    end
    return 'a few seconds ago'
  end
  
  def duration(length)
    if length == 0
      return '--:--'
    end
    length = length.to_f
    seconds = (length % 100).to_i.to_s
    minutes = (length % 10000).to_i.to_s
    if seconds.length < 2
      seconds = '0' + seconds
    end
    if minutes.length < 2
      minutes = '0' + minutes
    end
    if seconds.length < 2
      seconds = '0' + seconds
    end
    hours = (length / 10000).to_i
    if hours <= 0
      return minutes + ':' + seconds
    end
    if hours < 10
      hours = '0' + hours.to_s
    end
    return hours + ':' + minutes + ':' + seconds
  end
end
