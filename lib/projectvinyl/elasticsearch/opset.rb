require 'projectvinyl/elasticsearch/lexer_error'
require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class Opset
      def initialize(search_terms, index_params)
        @index_params = index_params
        @buffer = []
        @open_count = 0
        @old = []
        if !search_terms || (search_terms = search_terms.strip).empty?
          @terms = []
        else
          @terms = search_terms.split('')
        end
      end

      def length
        @terms.length + @buffer.length
      end

      def peek(n)
        while @buffer.length < n && !@terms.empty?
          stack = @buffer
          @buffer = []
          stack << __shift
          @buffer.each do |i|
            stack << i
          end
          @buffer = stack
        end
        result = []
        for i in 0..(n - 1)
          if i < @buffer.length
            result << @buffer[i]
          else
            result << ""
          end
        end
        result
      end

      def push(value)
        @buffer << value
      end

      def shift_data(op, parameter)
        data = shift
        if !data.nil? && (true.is_a?(data.class) || 1.is_a?(data.class) || !data.empty?)
          yield(data) if block_given?
          return data
        end

        raise LexerError, Op.name_of(op) + " Operator requires parameter: " + parameter
      end


      def shift
        return @buffer.shift if !@buffer.empty?
        __shift
      end

      def slurp_quoted_text(quote_char, slurp)
        until @terms.empty?
          i = @terms.shift

          if i == quote_char
            return slurp
          end

          slurp += i
        end

        slurp
      end

      def __shift
        slurp = ""
        prev = !@old.empty? ? @old.last : ''
        until @terms.empty?
          i = @terms.shift
          @old << i

          if i == '"' || i == '\''
            slurp = slurp_quoted_text(i, slurp)
          else
            if i == ' '
              # consume spaces around operators
              if prev == ',' || prev == '&' || prev == '|'
                prev = i
                next
              end
            end

            if !slurp.empty?
              if i == ',' || (prev == ' ' && i == '&')
                o = @index_params.slurp_tags(self, slurp)
                push Op::AND
                return o
              elsif prev == ' ' && i == '|'
                o = @index_params.slurp_tags(self, slurp)
                push Op::OR
                return o
              elsif i == ')' && prev != '\\'
                if @open_count > 0
                  @open_count -= 1
                  o = @index_params.slurp_tags(self, slurp)
                  push Op::GROUP_END
                  return o
                else
                  slurp << i
                end
              else
                slurp << i
              end
            elsif i == '(' && prev != '\\'
              @open_count += 1
              return Op::GROUP_START
            elsif i == ')' && prev != '\\'
              if @open_count > 0
                @open_count -= 1
                return Op::GROUP_END
              else
                slurp << i
              end
            else
              if i == '-'
                return Op::NOT
              else
                slurp << i
              end
            end
          end

          prev = i
        end

        return @index_params.slurp_tags(self, slurp) if !slurp.empty?

        if @open_count != 0
          raise LexerError, "Unmatched '(' for + '" + @old + "|" + @terms.join('') + "'!"
        end

        raise "Pointer overrun!"
      end
    end
  end
end
