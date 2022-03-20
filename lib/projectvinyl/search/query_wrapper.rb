require 'projectvinyl/search/exceptable'

module ProjectVinyl
  module Search
    class QueryWrapper
      def initialize(exceptable, table, ids, params)
        @exceptable = exceptable
        @table = table
        @ids = ids
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
        distrust([]) do
          @search.map(&:id).map(&:to_i)
        end
      end

      def total
        return 0 if @exception
        distrust do
          @search.results.total
        end
      end

      def count
        return 0 if @exception
        distrust do
          @search.count
        end
      end

      def records
        return @table.none if total == 0
        return @search.records if @ids.nil?
        @search.records.order("position(videos.id::text in '#{@ids.join(',')}')")
      end

      private
      def distrust(v = 0)
        return yield
      rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable => e
        excepted! e, v
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        excepted! e, v
      rescue Faraday::ConnectionFailed => e
        excepted! e, v
      end

      def excepted!(e, v = nil)
        @exception = e
        @exceptable.excepted! e
        v
      end
    end
  end
end
