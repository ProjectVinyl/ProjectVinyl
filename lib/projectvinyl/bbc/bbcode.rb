require 'projectvinyl/bbc/parser/node_document_parser'
require 'projectvinyl/bbc/emoticons'
require 'projectvinyl/bbc/embed_generator'
require 'projectvinyl/bbc/tag_generator'

module ProjectVinyl
  module Bbc
    module Bbcode
      TagGenerator.register(:bbc, [:br]){|tag| "\n#{tag.inner_bbc}" }
      TagGenerator.register(:bbc, [:hr]){|tag| "[hr]#{tag.inner_bbc}" }
      TagGenerator.register(:bbc, [:timestamp]){|tag| tag.inner_bbc }
      TagGenerator.register(:bbc, [:b,:u,:s,:sup,:sub,:spoiler]){|tag| "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]" }
      TagGenerator.register(:bbc, [:div]){|tag| tag.classes.include?('spoiler') ? "[spoiler]#{tag.inner_bbc}[/spoiler]" : tag.inner_bbc }
      TagGenerator.register(:bbc, [:img]){|tag| "[img#{tag.attributes.only(:alt, :title).to_html}]#{tag.attributes[:src]}[/img]#{tag.inner_bbc}" }
      TagGenerator.register(:bbc, [:emote]){|tag| ":#{tag.inner_text}:" }
      TagGenerator.register(:bbc, [:blockquote]){|tag| "[q#{tag.attributes.only(:who, :when).to_html}]#{tag.inner_bbc}[/q]" }
      TagGenerator.register(:bbc, [:at]){|tag| "@#{tag.inner_text}" }
      TagGenerator.register(:bbc, [:reply]){|tag| ">>#{tag.inner_text}" }
      TagGenerator.register(:bbc, [:i]) do |tag|
        next ":#{tag.attributes[:data_emote]}:" if tag.classes.include?('emote')
        next "[icon]#{tag.attributes[:class].sub('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0]}[/icon]" if tag.attributes[:class] && tag.attributes[:class].index('fa fa-fw fa-')
        "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]"
      end
      TagGenerator.register(:bbc, [:a]) do |tag|
        next tag.inner_bbc if !tag.attributes[:href]
        next "@#{tag.inner_text}" if tag.classes.include?('user-link')
        next tag.attributes[:href] if tag.attributes[:data_link] == '1'
        next ">>#{tag.attributes[:href].sub('#comment_', '')}" if tag.attributes[:data_link] == '2'
        "[url=#{tag.attributes[:href]}]#{tag.inner_bbc}[/url]"
      end
      TagGenerator.register(:bbc, [:iframe]) do |tag|
        if tag.attributes[:src] && tag.attributes[:class] == 'embed'
          next "[embed]#{Web::Youtube.video_id(tag.attributes[:src])}[/embed]#{tag.inner_bbc}" if Web::Youtube.is_video_link(tag.attributes[:src])
          next "[embed]#{Web::Peertube.video_id(tag.attributes[:src])}[/embed]#{tag.inner_bbc}" if Web::Peertube.is_video_link(tag.attributes[:src])
          next "[embed]#{Web::Dailymotion.video_id(tag.attributes[:src])}[/embed]#{tag.inner_bbc}" if Web::Dailymotion.is_video_link(tag.attributes[:src])
          next "[#{tag.attributes[:src].gsub(/[^0-9]/,'')}]#{tag.inner_bbc}"
        end
        tag.inner_bbc
      end

      TagGenerator.register(:html, [:b,:i,:u,:s,:sup,:sub,:hr]){|tag| "<#{tag.tag_name}>#{tag.inner_html}</#{tag.tag_name}>" }
      TagGenerator.register(:html, [:icon]){|tag| "<i class=\"fa fa-fw fa-#{tag.inner_text.split(/[^a-zA-Z0-9]/)[0]}\"></#{tag.tag_name}>" }
      TagGenerator.register(:html, [:q]){|tag| "<blockquote#{!tag.even ? ' class="even"' : ''}#{tag.attributes.only(:who, :when).to_html}>#{tag.inner_html}</blockquote>" }
      TagGenerator.register(:html, [:url]){|tag| "<a rel=\"noopener ugc nofollow\" href=\"#{tag.equals_par  || tag.inner_text}\">#{tag.inner_html}</a>" }
      TagGenerator.register(:html, [:a]){|tag| "<#{tag.tag_name} rel=\"noopener ugc nofollow\"#{tag.attributes.only(:href).to_html}>#{tag.inner_html}</#{tag.tag_name}>" }
      TagGenerator.register(:html, [:br]){|tag| "<#{tag.tag_name} />#{tag.inner_html}"}
      TagGenerator.register(:html, [:embed]){|tag| EmbedGenerator.generate_embed(tag) }
      TagGenerator.register(:html, [:spoiler]){|tag| "<div class=\"spoiler\">#{tag.inner_html}</div>" }
      TagGenerator.register(:html, [:img]){|tag| "<img#{tag.attributes.only(:alt, :title).to_html} src=\"#{tag.inner_text.gsub(/['"]/,'')}\"></img>" }
      TagGenerator.register(:html, [:emote]){|tag| Emoticons.emoticon_tag(tag.inner_text) }
      TagGenerator.register(:html, [:size]){|tag| "<span data-size=\"#{tag.equals_par}\">#{tag.inner_html}</span>" }
      TagGenerator.register(:html, [:at]){|tag| tag.resolve_dynamically{ "<a class=\"user-link\" data-id=\"0\">#{tag.inner_text}</a>" } }
      TagGenerator.register(:html, [:reply]){|tag| tag.resolve_dynamically{ "<a data-link=\"2\" href=\"#comment_#{tag.inner_text}\">#{tag.inner_text}</a>" } }
      TagGenerator.register(:html, [:timestamp]){|tag| tag.resolve_dynamically{ "<a data-time=\"#{tag.attributes[:time]}\">#{tag.inner_html}</a>" } }

      def self.from_html(html)
        Parser::NodeDocumentParser.parse(html, '<', '>')
      end

      def self.from_bbc(bbc)
        Parser::NodeDocumentParser.parse(bbc, '[', ']')
      end
    end
  end
end