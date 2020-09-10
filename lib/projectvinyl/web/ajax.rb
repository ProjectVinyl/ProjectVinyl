require 'net/http'

module ProjectVinyl
  module Web
    class Ajax
      attr_accessor :params, :url

      def self.get(url, params = {})
        Ajax.new(url).get(params) do |body|
          yield(body)
        end
      end

      def self.post(url, params = {})
        Ajax.new(url).post(params) do |body|
          yield(body)
        end
      end

      def initialize(url)
        @url = URI.parse(url)
        @params = {}
        @url.query.split('&').each do |i|
          i = i.split('=')
          @params[i[0]] = i[1]
        end
      end

      def request
        res = Net::HTTP.start(@url.host, @url.port,
                              use_ssl: @url.scheme == 'https',
                              verify_mode: OpenSSL::SSL::VERIFY_NONE) do |connection|
          connection.request(@req)
        end
        
        if (res.code.to_i / 100).floor == 2
          yield(res.body)
          return true
        end
        
        false
      end

      def get(params = {})
        @url.query = URI.encode_www_form(@params.merge(params))
        @req = Net::HTTP::Get.new(@url)
        self.request do |body|
          yield(body)
        end
      end

      def post(params = {}, headers = nil)
        if headers.nil?
          @req = Net::HTTP::Post.new(@url)
          @req.set_form_data(@params.merge(params))
        else
          @req = Net::HTTP::Post.new(@url, headers)
          @req.body = params
        end
        
        self.request do |body|
          yield(body)
        end
      end
    end
  end
end