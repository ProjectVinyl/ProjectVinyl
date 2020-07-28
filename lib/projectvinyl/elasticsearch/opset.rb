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
        @terms = !search_terms || (search_terms = search_terms.strip).empty? ? [] : search_terms.split('')
      end

      def length
        @terms.length + @buffer.length
      end

      def peek(n)

        # If the buffer is too small, look ahead in the search query to initialise more terms
        while (n < 0 || @buffer.length < n) && !@terms.empty?
          stack = @buffer
          @buffer = []              # store the previous buffer state
          stack << __shift          # shift a new operator onto the stack
          @buffer = stack + @buffer # shift any new buffered terms into the end of the stack
        end

        result = []           # pop off n results from the buffer

        n = length if n < 0   # if called with a negative number output the entire parsed length.
                              # Used for debugging

        for i in 0..(n - 1)
          result << (i < @buffer.length ? @buffer[i] : '')
        end

        result
      end

      def push(value)
        @buffer << value
      end

      def shift_data(op, parameter)
        begin
          data = shift
        rescue InputError => e
          raise LexerError, "#{Op.name_of(op)} Operator requires parameter: #{parameter}"
        end

        if data.nil? || true.is_a?(data.class) || 1.is_a?(data.class) || !data.empty?
          yield(data) if block_given?
          return data
        end

        raise LexerError, "#{Op.name_of(op)} Operator requires parameter: #{parameter}"
      end


      def shift
        return @buffer.shift if !@buffer.empty?
        __shift
      end

      private
      def __slurp_quoted_text(quote_char, slurp)
        until @terms.empty?
          i = @terms.shift
          return slurp if i == quote_char
          slurp += i
        end

        slurp
      end

      def __change_nesting(logical_op, step)
        @open_count += step
        logical_op
      end

      def __read_logical(slurp, logical_op)
        return logical_op if slurp.empty?

        o = @index_params.slurp_tags(self, slurp)
        push logical_op
        o
      end

      # Handles all the logical operatorations. (AND, OR, NOT, GROUP_START, GROUP_END)
      def __shift
        slurp = ''
        prev = !@old.empty? ? @old.last : ''
        i = prev

        until @terms.empty?
          prev = i
          i = @terms.shift
          @old << i

          # consume quoted strings
          if i == '"' || i == '\''
            slurp = __slurp_quoted_text(i, slurp)
            next
          end

          if prev != '\\'
            # consume spaces coming after operators
            next if i == ' ' && (prev == ',' || prev == '&' || prev == '|' || prev == ')' || prev == '(')
            return Op::NOT if i == '-' && slurp.empty?
            return __change_nesting(Op::GROUP_START, 1) if i == '(' && slurp.empty?
            return __read_logical(slurp, Op::AND) if i == ',' || (prev == ' ' && i == '&')
            return __read_logical(slurp, Op::OR) if prev == ' ' && i == '|'
            return __read_logical(slurp, __change_nesting(Op::GROUP_END, -1)) if i == ')' && @open_count > 0
          end

          slurp << i
        end

        return @index_params.slurp_tags(self, slurp) if !slurp.empty?

        raise LexerError, "Unmatched '(' for + '" + @old + "|" + @terms.join('') + "'!" if @open_count != 0
        raise InputError, "Pointer overrun!"
      end
    end
  end
end
