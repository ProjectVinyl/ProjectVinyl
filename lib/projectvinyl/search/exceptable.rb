module ProjectVinyl
  module Search
    module Exceptable
      attr_reader :exception, :exception_type

      def lexer_error?
        exception_type == 2
      end

      def input_error?
        exception_type == 1
      end

      def excepted(exceptable)
        return excepted!(exceptable.exception, exceptable.exception_type) if exception.nil?
        self
      end

      def excepted!(e, type = 0)
        return self if e.nil?
        return self if !exception_type.nil? && exception_type > type

        @exception = e
        @exception_type = type
        self
      end
    end
  end
end
