require 'projectvinyl/web/ajax'
require 'projectvinyl/bbc/bbcode'
require 'uri'

module ProjectVinyl
  module Web
    class UnlistedVideos
      API_URL = 'https://unlistedvideos.com/v.php'

      def self.video_meta(video_id)
        # Private video
        #  https://www.youtube.com/watch?v=7XBVP8PeOr4
        #  https://unlistedvideos.com/v.php?youtube-7XBVP8PeOr4
        #  Title: Antibronies (more autistic than bronies.)
        #  Uploaded by: NRGpony
        #  Published on: 8 September 2014
        #  Description: Top kek m80
        # Unlisted (recorded)
        #  https://unlistedvideos.com/v.php?youtube-e1SxRTjQi74
        #  Uploaded by: NRGpony
        #  Published on: 14 March 2014
        #  Brony Parkour 2, because some people were asking for it. Also the first half sucks.
        #
        #  Now before you get all uppidy about the fucking lady who I was yelling at just hear me out. I went over to her church to go get some footage and she yelled at me for climbing a fence, she told me to leave and without a word I did. As I was walking away from the church I saw the two same women pull out of the driveway of the church, in doing so they gave me a childish face. So, in responce to there immaturity, I gave them a face back. Then all that shit happend. I shouldn't have, but it did.
        #
        #  Music
        #  Taps - Tartarus
        #  https://www.youtube.com/watch?v=7OqcmlQrjRY
        #
        #  the pharcyde passin me by instrumental
        #  https://www.youtube.com/watch?v=U7qjZ_VRyM8
        # Unlisted (recorded)
        #  https://unlistedvideos.com/v.php?youtube-34oOqCVHzMc
        # Public (not recorded)
        #  https://unlistedvideos.com/v.php?youtube-MM989eGz6m8

        output = Ajax.get("#{API_URL}?youtube-#{video_id}")
        return {} if output.nil?
        document = ProjectVinyl::Bbc::Bbcode.from_html(output)

        title = document.getElementsByTagName('h1').first
        title = title.inner_text if title.present?
        
        # Date uploaded/published to YouTube: 
        published = ProjectVinyl::Bbc::Bbcode.from_html(output.split('Date uploaded/published to YouTube: ')[1] || '')
          .getElementsByTagName('td')
          .map{|td| td.inner_text}
          .first || ''

        channel = document.getElementsByTagName('a').filter{|a| a.classes.include?('greenlink')}.first
        channel = channel.inner_text if channel.present?

        body = document.getElementsByTagName('table')[2]

        output = body.inner_html.split('Description:')[1].split('removemyvideo.php')[0].gsub('\t', '')
        document = ProjectVinyl::Bbc::Bbcode.from_html(output).inner_bbc
        document = document.gsub('[url=][/url]', '').strip
        document = ProjectVinyl::Bbc::Bbcode.from_bbc(document)

        {
          title: title,
          channel: channel,
          publish_date: published.to_date,
          description: document.to_json
        }
      end
    end
  end
end
