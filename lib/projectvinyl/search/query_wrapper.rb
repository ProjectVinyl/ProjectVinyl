require 'projectvinyl/search/exceptable'

module ProjectVinyl
  module Search
    class QueryWrapper
      def initialize(exceptable, table, params)
        @exceptable = exceptable
        @table = table
        @search = table.search params
      rescue Faraday::ConnectionFailed => e
        excepted! e
        nil
      rescue => e
        excepted! e
        puts "Exception raised #{e}"
        puts "Backtrace:\n\t#{e.backtrace[0..8].join("\n\t")}"
        nil
      end

      def ids
        return [] if @exception
        @search.map(&:id).map(&:to_i)
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        excepted! e, []
      rescue Faraday::ConnectionFailed => e
        excepted! e, []
      end

      def total
        return 0 if @exception
        @search.results.total
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        excepted! e, 0
      rescue Faraday::ConnectionFailed => e
        excepted! e, 0
      end

      def count
        return 0 if @exception
        @search.count
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        excepted! e, 0
      rescue Faraday::ConnectionFailed => e
        excepted! e, 0
      end

      def records
        return @table.none if total == 0
        @search.records
      end
      
      private
      def excepted!(e, v = nil)
        @exception = e
        @exceptable.excepted! e
        v
      end
    end
  end
end
