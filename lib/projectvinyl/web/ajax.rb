require 'net/http'

module ProjectVinyl
  module Web
    class Ajax
      attr_accessor :params, :url

      def self.get(url, params = {})
        Ajax.new(url).get(params)
      end

      def initialize(url)
        @url = URI.parse(url)
        @params = {}
        if @url.query
          @url.query.split('&').each do |i|
            i = i.split('=')
            @params[i[0]] = i[1]
          end
        end
      end

      def request
        res = Net::HTTP.start(@url.host, @url.port,
                              use_ssl: @url.scheme == 'https',
                              verify_mode: OpenSSL::SSL::VERIFY_NONE) do |connection|
          connection.request(@req)
        end

        return res.body if (res.code.to_i / 100).floor == 2
        nil
      end

      def get(params = {})
        @url.query = URI.encode_www_form(@params.merge(params))
        @req = Net::HTTP::Get.new(@url)
        self.request
      end
    end
  end
end