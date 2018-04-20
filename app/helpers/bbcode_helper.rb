require 'projectvinyl/bbc/bbcode'

module BbcodeHelper
  SIZE = 32
  
  def self.emoticons
    ProjectVinyl::Bbc::Emoticons.all
  end
  
  def emoticon_tag(name)
    raw (ProjectVinyl::Bbc::Emoticons.is_defined_emote(name) ? ProjectVinyl::Bbc::Emoticons.emoticon_tag(name) : '')
  end
  
  def self.emotify(text)
    if text.blank?
      return ''
    end
    
    ProjectVinyl::Bbc::Bbcode.from_bbc(text).outer_html
  end
  
  def self.each_tile_asset
    emoticons.each_with_index do |emoticon,index|
      yield(emoticon, (index % 7) * SIZE, (index / 7).floor * SIZE)
    end
  end
end
