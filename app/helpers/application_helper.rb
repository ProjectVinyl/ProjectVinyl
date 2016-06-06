module ApplicationHelper
  Emoticons =   [
    "ajbemused",
    "ajsleepy",
    "ajsmug",
    "applejackconfused",
    "applejackunsure",
    "applecry",
    "eeyup",
    "fluttercry",
    "flutterrage",
    "fluttershbad",
    "fluttershyouch",
    "fluttershysad",
    "yay",
    "heart",
    "pinkiecrazy",
    "pinkiegasp",
    "pinkiehappy",
    "pinkiesad2",
    "pinkiesmile",
    "pinkiesick",
    "twistnerd",
    "rainbowderp",
    "rainbowdetermined2",
    "rainbowhuh",
    "rainbowkiss",
    "rainbowlaugh",
    "rainbowwild",
    "scootangel",
    "raritycry",
    "raritydespair",
    "raritystarry",
    "raritywink",
    "duck",
    "unsuresweetie",
    "coolphoto",
    "twilightangry2",
    "twilightoops",
    "twilightblush",
    "twilightsheepish",
    "twilightsmile",
    "facehoof",
    "moustache",
    "trixieshiftleft",
    "trixieshiftright",
    "derpyderp1",
    "derpyderp2",
    "derpytongue2",
    "trollestia"
  ]
  def emotify(text)
    text = text.gsub(/\n/,'<br>').gsub(/([buis])\]/, '[\1]').gsub(/\[\/([buis])\]/, '</\1>')
    Emoticons.each { |x|
      text = text.gsub(/:#{x}:/,'<img class="emoticon" src="/emoticons/' + x + '.png">')
    }
    return text
  end
  
  def self.demotify(text)
    text = text.gsub(/\<br\>/,'\n').gsub(/\<([buis])\>/, '[\1]').gsub(/\<\/([buis])\>/, '[/\1]')
    Emoticons.each { |x|
      text = text.gsub(/<img class="emoticon" src="\/emoticons\/#{x}">:/,':' + x + ':">')
    }
    return text
  end
  
  def demotify(text)
    return ApplicationHelper.demotify(text)
  end
  
  def emoticons
    return Emoticons
  end
  
  @current_artist = nil
  def current_artist
    if user_signed_in?
      return @current_artist || @current_artist = Artist.where(id: current_user.artist_id).first
    end
    return nil
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
    hours = 0
    if length > 3600
      hours = (length/3600).floor.to_i
      length = length % 3600
    end
    minutes = 0
    if length > 60
      minutes = (length/60).floor.to_i
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
    return hours.to_s + ':' + minutes.to_s + ':' + seconds.to_s
  end
  
  def url_safe(txt)
    return txt.gsub(/\//,'+')
  end
  
  def self.url_unsafe(txt)
    return txt.gsub(/%2B|\+/, '/')
  end
  
  def title(page_title)
    content_for(:title) { page_title }
  end
  
  def lim(page_width)
    content_for(:width) { page_width }
  end
end
