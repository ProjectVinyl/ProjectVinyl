module ProjectVinyl
  class Csp
    def self.parse(hash)
      hash = hash.map do |key, value|
        "#{key.to_s.gsub('_','-')} #{value.join(' ').gsub(/(self|unsafe-inline|none)/, '\'\1\'')};"
      end
      hash.join('')
    end
    
    def self.headers
      HEADERS
    end
    
    HEADERS = {
      default: Csp.parse({
        default_src: [ 'self', 'http://upload.lvh.me:8080', 'http://upload.projectvinyl.net', 'https://upload.projectvinyl.net' ],
        form_action: [ 'self', 'http://upload.lvh.me:8080', 'http://upload.projectvinyl.net', 'https://upload.projectvinyl.net' ],
        worker_src: [ 'self' ],
        child_src: [ 'self', 'https://www.youtube.com', 'https://www.dailymotion.com', 'https://vault.mle.party', 'https://www.recaptcha.net' ],
        frame_src: [ 'self', 'https://www.youtube.com', 'https://www.dailymotion.com', 'https://vault.mle.party', 'https://www.recaptcha.net' ],
        media_src: [ 'self', 'blob:' ],
        img_src: [ '*', 'blob:', 'data:' ],
        script_src: [ 'self', 'https://www.google.com/recaptcha/api.js', 'https://www.gstatic.com', 'https://www.recaptcha.net/recaptcha/api.js' ],
        style_src: [ 'self', 'unsafe-inline' ]
      }),
      embed: Csp.parse({
        default_src: [ 'self' ],
        form_action: [ 'self' ],
        frame_ancestors: [ '*' ],
        worker_src: [ 'self' ],
        frame_src: [ 'self' ],
        child_src: [ 'self' ],
        media_src: [ 'self', 'blob:' ],
        img_src: [ '*', 'blob:', 'data:' ],
        script_src: [ 'self' ],
        style_src: [ 'self', 'unsafe-inline' ]
      }),
      twitter: Csp.parse({
        default_src: [ 'self' ],
        form_action: [ 'self', 'https://syndication.twitter.com/' ],
        frame_ancestors: [ 'self' ],
        worker_src: [ 'self', 'https://www.youtube.com' ],
        child_src: [ 'self', 'https://www.youtube.com', 'https://platform.twitter.com/' ],
        frame_src: [ 'self', 'https://www.youtube.com', 'https://platform.twitter.com/', 'https://syndication.twitter.com/' ],
        media_src: [ 'self', 'blob:' ],
        img_src: [ '*', 'blob:', 'data:' ],
        script_src: [ 'self', 'unsafe-inline', 'http://platform.twitter.com/', 'http://196.25.211.41/', 'https://cdn.syndication.twimg.com/' ],
        style_src: [ 'self', 'unsafe-inline', 'http://platform.twitter.com/', 'https://ton.twimg.com' ]
      })
    }
  end
end
