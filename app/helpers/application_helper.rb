module ApplicationHelper
  Emoticons =   [
    "ajbemused",
    "ajsleepy",
    "ajsmug",
    "applejackconfused",
    "applejackunsure",
    "applecry",
    "fluttercry",
    "flutterrage",
    "fluttershbad",
    "fluttershyouch",
    "fluttershysad",
    "yay",
    "pinkiecrazy",
    "pinkiegasp",
    "pinkiehappy",
    "pinkiesad2",
    "pinkiesmile",
    "pinkiesick",
    "rainbowderp",
    "rainbowdetermined2",
    "rainbowhuh",
    "rainbowkiss",
    "rainbowlaugh",
    "rainbowwild",
    "raritycry",
    "raritydespair",
    "raritystarry",
    "raritywink",
    "duck",
    "unsuresweetie",
    "twilightangry2",
    "twilightoops",
    "twilightblush",
    "twilightsheepish",
    "twilightsmile",
    "facehoof",
    "cheericonfused",
    "cheeriderp",
    "cheerismile",
    "derpyderp1",
    "derpyderp2",
    "derpytongue2",
    "heart",
    "eeyup",
    "twistnerd",
    "twistoo",
    "scootangel",
    "coolphoto",
    "moustache",
    "trixieshiftleft",
    "trixieshiftright",
    "trollestia",
    "redheartgasp",
    "zecora"
  ]
  
  def self.read_only
    false
  end
  
  def self.check_and_trunk(str, defa)
    if !str || (str = str.strip).length == 0
      return defa
    end
    if str.length > 250
      return str[0,250]
    end
    return str
  end
  
  def self.emoticons
    Emoticons
  end
  
  def emoticons
    Emoticons
  end
  
  def assets_version
    1
  end
  
  def self.emotify(text)
    if text.nil? || text.length == 0
      return ""
    end
    text = text.gsub(/\[icon\]([^\[]+)\[\/icon\]/, '<i class="fa fa-fw fa-\1"></i>')
    text = text.gsub(/\n/,'<br>').gsub(/\[([\/]?([buis]|sup|sub|hr))\]/, '<\1>').gsub(/\[([\/]?)q\]/, '<\1blockquote>')
    text = text.gsub(/\[url=([^\]]+)\]/,'<a href="\1">').gsub(/\[\/url\]/,'</a>')
    text = text.gsub(/\[img\]([^\]]+)\[\/img\]/, '<span class="img"><img src="\1"></span>')
    text = text.gsub(/([^">]|[\s\n]|<[\/]?br>|^)(http[s]?:\/\/[^\s\n<]+)([^"<]|[\s\n]|<br>|$)/, '\1<a data-link="1" href="\2">\2</a>\3')
    text = text.gsub(/\[spoiler\]/, '<div class="spoiler">').gsub(/\[\/spoiler\]/, '</div>')
    Emoticons.each { |x|
      text = text.gsub(/:#{x}:/,'<img class="emoticon" src="/emoticons/' + x + '.png">')
    }
    return StathamSanitizer.new.sanitize(text, tags: %w(i b u s sup sub hr blockquote br img a div span), attributes: %w(class style href src data-link data-id),
           styles: %w(max-width))
  end
  
  def self.demotify(text)
    if text.nil? || text.length == 0
      return ""
    end
    text = text.gsub(/<i class="fa fa-fw fa-([^"]+)"><\/i>/, '[icon]\1[/icon]')
    text = text.gsub(/<br>/,'\n').gsub(/<([\/]?([buis]|sup|sub))>/, '[\1]').gsub(/<([\/]?)blockquote>/, '[\1q]')
    text = text.gsub(/<a data-link="1" href="([^"]+)">[^<]*<\/a>/, '\1')
    text = text.gsub(/<a href="([^"]+)"\>/, '[url=\1]').gsub(/<\/a>/,'[/url]')
    text = text.gsub(/<div class="spoiler">/, '[spoiler]').gsub(/<\/div>/,'[/spoiler]')
    text = text.gsub(/<\/img>/,'').gsub(/<span class="img"><img src="([^"]+)"><\/span>/, '[img]\1[/img]')
    Emoticons.each { |x|
      text = text.gsub(/<img class="emoticon" src="\/emoticons\/#{x}">:/,':' + x + ':">')
    }
    text.gsub(/</, '&lt;').gsub(/>/, '&gt;')
  end
  
  def demotify(text)
    ApplicationHelper.demotify(text)
  end
  
  def since(date)
    (time_ago_in_words date) + " ago"
  end
  
  def duration(length)
    if length == 0
      return '--:--'
    end
    length = length.to_f
    hours = 0
    if length >= 3600
      hours = (length/3600).floor.to_i
      length = length % 3600
    end
    minutes = 0
    if length >= 60
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
    hours.to_s + ':' + minutes.to_s + ':' + seconds.to_s
  end
  
  def self.url_safe(txt)
    txt.gsub(/(\/|[^:\!\@\$\^&\*\(\)\+=_;:'",a-zA-Z0-9\-])+/,'-').gsub(/--/,'-').gsub(/(^-)|(-$)/,'')
  end
  
  def self.url_safe_for_tags(txt)
    txt.gsub(/(\/|[^:\!\@\$\^&\*\(\)\+=_;:'",a-zA-Z0-9 \-])+/,'-').gsub(/--/,'-').gsub(/(^-)|(-$)/,'')
  end
  
  def title(page_title)
    content_for(:title) { page_title }
  end
  
  def lim(page_width)
    content_for(:width) { page_width }
  end
  
  def load_time
    Time.now - @start_time
  end
  
  def self.valid_string?(s)
    s && s.length > 0
  end
  
  def valid_string(s)
    ApplicationHelper.valid_string(s)
  end
end
