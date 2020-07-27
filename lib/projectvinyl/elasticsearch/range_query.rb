require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class RangeQuery
      def initialize
        @ranges = {}
        @dirty = false
      end

      attr_reader :dirty

      def record(op, opset, invert)
        field = opset.shift_data(op, 'field')
        value = opset.shift_data(op, 'value')

        greater_than = op == Op::GREATER_THAN
        @ranges[field] = {} if !@ranges.key?(field)
        @ranges[field][invert ? (greater_than ? :lte : :gte) : (greater_than ? :gt : :lt)] = deserialize(field, value)
        @dirty = true
      end

      def deserialize(field, value)
        return Ffmpeg.from_h_m_s(value) if field == :length
        return DateTime.parse(value) if field == :created_at || field == :updated_at
        value.to_i
      end

      def compile(dest)
        if @dirty
          @ranges.keys.each do |field|
            dest << {
              range: { field => @ranges[field] }
            }
          end
        end

        dest
      end
    end
  end
end
