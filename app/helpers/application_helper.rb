module ApplicationHelper
  Emoticons = %w[
    ajbemused
    ajsleepy
    ajsmug
    applejackconfused
    applejackunsure
    applecry
    eeyup
    fluttercry
    flutterrage
    fluttershbad
    fluttershyouch
    fluttershysad
    yay
    heart
    pinkiecrazy
    pinkiegasp
    pinkiehappy
    pinkiesad2
    pinkiesmile
    pinkiesick
    coolphoto
    rainbowderp
    rainbowdetermined2
    rainbowhuh
    rainbowkiss
    rainbowlaugh
    rainbowwild
    iwtcird
    raritycry
    raritydespair
    raritystarry
    raritywink
    duck
    unsuresweetie
    scootangel
    twilightangry2
    twilightoops
    twilightblush
    twilightsheepish
    twilightsmile
    facehoof
    moustache
    twistnerd
    twistoo
    trixieshiftleft
    trixieshiftright
    cheericonfused
    cheeriderp
    cheerismile
    derpyderp1
    derpyderp2
    derpytongue2
    trollestia
    redheartgasp
    zecora
  ].freeze

  def self.read_only
    false
  end

  def self.check_and_trunk(str, defa)
    if !str || (str = str.strip).empty?
      return defa
    end
    return str[0, 250] if str.length > 250
    str
  end

  def self.emoticons
    Emoticons
  end

  def emoticons
    Emoticons
  end

  def assets_version
    7
  end

  def self.emotify(text)
    return "" if text.blank?
    text = text.gsub(/\[icon\]([^\[]+)\[\/icon\]/, '<i class="fa fa-fw fa-\1"></i>')
    text = text.gsub(/\n/, '<br>').gsub(/\[([\/]?([buis]|sup|sub|hr))\]/, '<\1>').gsub(/\[([\/]?)q\]/, '<\1blockquote>')
    text = text.gsub(/\[url=([^\]]+)\]/, '<a href="\1">').gsub(/\[\/url\]/, '</a>')
    text = text.gsub(/\[img\]([^\]]+)\[\/img\]/, '<span class="img"><img src="\1"></span>')
    text = text.gsub(/([^">]|[\s\n]|<[\/]?br>|^)(http[s]?:\/\/[^\s\n<]+)([^"<]|[\s\n]|<br>|$)/, '\1<a data-link="1" href="\2">\2</a>\3')
    text = text.gsub(/([^">]|[\s\n]|<[\/]?br>|^)(>>|&gt;&gt;)([0-9a-z]+)([^"<]|[\s\n]|<br>|$)/, '\1<a data-link="2" href="#comment_\3">\2\3</a>\4')
    text = text.gsub(/\[spoiler\]/, '<div class="spoiler">').gsub(/\[\/spoiler\]/, '</div>')
    Emoticons.each do |x|
      text = text.gsub(/:#{x}:/, '<img class="emoticon" src="/emoticons/' + x + '.png">')
    end
    text = StathamSanitizer.new.sanitize(text, tags: %w[i b u s sup sub hr blockquote br img a div span], attributes: %w[class style href src data-link data-id],
                                               styles: %w[max-width])
    text = text.gsub(/\[([0-9]+)\]/, '<iframe class="embed" src="/embed/\1" allowfullscreen></iframe>')
    text.scan(/\[yt([^\]]+)\]/) do |match|
      text = text.sub('[yt' + match[0] + ']', '<iframe class="embed" src="https://www.youtube.com/embed/' + Youtube.video_id(match[0]) + '" allowfullscreen></iframe>')
    end
    text
  end

  def self.demotify(text)
    return "" if text.blank?
    text = text.gsub(/<i class="fa fa-fw fa-([^"]+)"><\/i>/, '[icon]\1[/icon]')
    text = text.gsub(/<br>/, '\n').gsub(/<([\/]?([buis]|sup|sub))>/, '[\1]').gsub(/<([\/]?)blockquote>/, '[\1q]')
    text = text.gsub(/<a data-link="1" href="([^"]+)">[^<]*<\/a>/, '\1')
    text = text.gsub(/<a data-link="2" href="[^"]+">([^<]*)<\/a>/, '\1')
    text = text.gsub(/<a href="([^"]+)"\>/, '[url=\1]').gsub(/<\/a>/, '[/url]')
    text = text.gsub(/<div class="spoiler">/, '[spoiler]').gsub(/<\/div>/, '[/spoiler]')
    text = text.gsub(/<\/img>/, '').gsub(/<span class="img"><img src="([^"]+)"><\/span>/, '[img]\1[/img]')
    Emoticons.each do |x|
      text = text.gsub(/<img class="emoticon" src="\/emoticons\/#{x}">:/, ':' + x + ':">')
    end
    text = text.gsub(/<iframe class="embed" src="\/embed\/([0-9+])" allowfullscreen><\/iframe>/, '[\1]')
    text = text.gsub(/<iframe class="embed" src="https:\/\/www.youtube.come\/embed\/([^&"]+)[^"]*" allowfullscreen><\/iframe>/, '[yt\1]')
    text.gsub(/</, '&lt;').gsub(/>/, '&gt;')
  end

  def demotify(text)
    ApplicationHelper.demotify(text)
  end

  def since(date)
    (time_ago_in_words date) + " ago"
  end

  def duration(length)
    return '--:--' if length == 0
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
    seconds = '0' + seconds.to_s if seconds < 10
    minutes = '0' + minutes.to_s if minutes < 10
    return minutes.to_s + ':' + seconds.to_s if hours == 0
    hours = '0' + hours.to_s if hours < 10
    hours.to_s + ':' + minutes.to_s + ':' + seconds.to_s
  end

  def selected_path?(type)
    if !@path_type
      @path_type = request.path.split('/')[1]
      @path_type = 'forum' if @path_type == 'thread'
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

  def query
    @query || params[:tagquery]
  end

  def search_type
    (params[:type] || 0).to_i || 0
  end

  def load_time
    Time.now - @start_time
  end

  def self.valid_string?(s)
    s.present?
  end

  def valid_string?(s)
    ApplicationHelper.valid_string?(s)
  end

  def safe_to_display(num, max)
    num ||= 0
    return number_with_delimiter(max) + '+' if num > max
    number_with_delimiter num
  end

  def email_escape(email)
    html_escape(email).gsub(/@/, '<i class="fa fa-at"></i>').html_safe
  end
end
