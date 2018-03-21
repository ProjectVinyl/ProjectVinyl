require 'projectvinyl/bbc/bbcode'

module BbcodeHelper
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
end
