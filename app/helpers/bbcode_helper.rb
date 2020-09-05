require 'projectvinyl/bbc/bbcode'

module BbcodeHelper

  def self.emoticons
    ProjectVinyl::Bbc::Emoticons.all
  end

  def emoticon_tag(name)
    raw (ProjectVinyl::Bbc::Emoticons.is_defined_emote(name) ? ProjectVinyl::Bbc::Emoticons.emoticon_tag(name) : '')
  end

  def self.emotify(text)
    if text.nil? || text.blank?
      return ''
    end

    Rails.cache.fetch(Ffmpeg.compute_checksum(text), expires_in: 24.hour) do
      Rails.logger.info('Rendering bbcode content')
      nodes = ProjectVinyl::Bbc::Bbcode.from_bbc(text)

      nodes.set_resolver do |trace, tag_name, tag, fallback|
        if tag_name == :at
          if user = User.find_for_mention(tag.inner_text)
            next "<a class=\"user-link\" data-id=\"#{user.id}\" href=\"#{user.link}\">#{user.username}</a>"
          end
        end

        fallback.call
      end

      nodes.outer_html
    end
  end

  def emotify(text)
    raw BbcodeHelper.emotify text
  end

  def self.each_tile_asset
    emoticons.each_with_index do |emoticon,index|
      yield(emoticon, index % 7, (index / 7).floor)
    end
  end
end
