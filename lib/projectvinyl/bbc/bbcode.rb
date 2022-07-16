require 'projectvinyl/bbc/parser/node_document_parser'
require 'projectvinyl/bbc/emoticons'
require 'projectvinyl/bbc/embed_generator'

module ProjectVinyl
  module Bbc
    class Bbcode
      TagGenerator.register(:bbc, [:br]) do |tag|
        "\n#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:hr]) do |tag|
        "[hr]#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:b,:u,:s,:sup,:sub,:spoiler]) do |tag|
        "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]"
      end
      TagGenerator.register(:bbc, [:i]) do |tag|
        if tag.classes.include?('emote')
          next ":#{tag.attributes[:data_emote]}:"
        end
        if tag.attributes[:class] && tag.attributes[:class].index('fa fa-fw fa-')
          next "[icon]#{tag.attributes[:class].sub('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0]}[/icon]"
        end
        "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]"
      end
      TagGenerator.register(:bbc, [:blockquote]) do |tag|
        "[q#{tag.attributes.only(:who, :when).to_html}]#{tag.inner_bbc}[/q]"
      end
      TagGenerator.register(:bbc, [:at]) do |tag|
        "@#{tag.inner_text}"
      end
      TagGenerator.register(:bbc, [:reply]) do |tag|
        ">>#{tag.inner_text}"
      end
      TagGenerator.register(:bbc, [:a]) do |tag|
        next tag.inner_bbc if !tag.attributes[:href]
        next "@#{tag.inner_text}" if tag.classes.include?('user-link')

        if tag.attributes[:data_link]
          next tag.attributes[:href] if tag.attributes[:data_link] == '1'
          next ">>#{tag.attributes[:href].sub('#comment_', '')}" if tag.attributes[:data_link] == '2'
        end

        "[url=#{tag.attributes[:href]}]#{tag.inner_bbc}[/url]"
      end
      TagGenerator.register(:bbc, [:div]) do |tag|
        next "[spoiler]#{tag.inner_bbc}[/spoiler]" if tag.classes.include?('spoiler')
        tag.inner_bbc
      end
      TagGenerator.register(:bbc, [:img]) do |tag|
        "[img#{tag.attributes.only(:alt, :title).to_html}]#{tag.attributes[:src]}[/img]#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:emote]) do |tag|
        ":#{tag.inner_text}:"
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
      TagGenerator.register(:bbc, [:timestamp]) do |tag|
        tag.inner_bbc
      end

      TagGenerator.register(:html, [:b,:i,:u,:s,:sup,:sub,:hr]) do |tag|
        "<#{tag.tag_name}>#{tag.inner_html}</#{tag.tag_name}>"
      end
      TagGenerator.register(:html, [:icon]) do |tag|
        "<i class=\"fa fa-fw fa-#{tag.inner_text.split(/[^a-zA-Z0-9]/)[0]}\"></#{tag.tag_name}>"
      end
      TagGenerator.register(:html, [:q]) do |tag|
        "<blockquote#{!tag.even ? ' class="even"' : ''}#{tag.attributes.only(:who, :when).to_html}>#{tag.inner_html}</blockquote>"
      end
      TagGenerator.register(:html, [:url]) do |tag|
        "<a rel=\"noopener ugc nofollow\" href=\"#{tag.equals_par  || tag.inner_text}\">#{tag.inner_html}</a>"
      end
      TagGenerator.register(:html, [:a]) do |tag|
        "<#{tag.tag_name} rel=\"noopener ugc nofollow\"#{tag.attributes.only(:href).to_html}>#{tag.inner_html}</#{tag.tag_name}>"
      end
      TagGenerator.register(:html, [:br]) do |tag|
        "<#{tag.tag_name} />#{tag.inner_html}"
      end
      TagGenerator.register(:html, [:at]) do |tag|
        tag.resolve_dynamically do
          "<a class=\"user-link\" data-id=\"0\">#{tag.inner_text}</a>"
        end
      end
      TagGenerator.register(:html, [:reply]) do |tag|
        tag.resolve_dynamically do
          "<a data-link=\"2\" href=\"#comment_#{tag.inner_text}\">#{tag.inner_text}</a>"
        end
      end
      TagGenerator.register(:html, [:embed]) do |tag|
        EmbedGenerator.generate_embed(tag)
      end
      TagGenerator.register(:html, [:spoiler]) do |tag|
        "<div class=\"spoiler\">#{tag.inner_html}</div>"
      end
      TagGenerator.register(:html, [:img]) do |tag|
        "<img#{tag.attributes.only(:alt, :title).to_html} src=\"#{tag.inner_text.gsub(/['"]/,'')}\"></img>"
      end
      TagGenerator.register(:html, [:emote]) do |tag|
        Emoticons.emoticon_tag(tag.inner_text)
      end
      TagGenerator.register(:html, [:size]) do |tag|
        "<span data-size=\"#{tag.equals_par}\">#{tag.inner_html}</span>"
      end
      TagGenerator.register(:html, [:timestamp]) do |tag|
        tag.resolve_dynamically do
          "<a data-time=\"#{tag.attributes[:time]}\">#{tag.inner_html}</a>"
        end
      end

      def self.from_html(html)
        Parser::NodeDocumentParser.parse(html, '<', '>')
      end

      def self.from_bbc(bbc)
        Parser::NodeDocumentParser.parse(bbc, '[', ']')
      end
    end
  end
end