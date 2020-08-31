require 'projectvinyl/search/parser/op'

module ProjectVinyl
  module Search
    module Parser
      class Index
        attr_reader :table

        def initialize(table, params = {}, &block)
          @table = table
          @params = params
          @default_func = block
        end

        def recognises?(slurp)
          return true if @params.key?(:hash) && slurp[0] == '#'

          slugs = slurp.split(/[<>:]/)
          return false if slugs.length < 2

          prefix = slugs[0]
          separator = slurp[prefix.length...(prefix.length + 1)].to_sym
          suffex = slurp[(prefix.length + 1)...slurp.length].strip.to_sym

          prefix = prefix.downcase.to_sym

          return true if pre_recognises_prefix?(:my, prefix, suffex)
          return true if pre_recognises_prefix?(:is, prefix, suffex)
          return true if post_recognises_prefix?(:by, prefix)
          return true if Op::CHAR_OP_LOOKUP.key?(separator) && post_recognises_prefix?(:range_fields, prefix)
          return true if post_recognises_prefix?(:has, prefix)
          return true if post_recognises_prefix?(:fields, prefix)
          false
        end

        def slurp_tags(opset, slurp)
          slurp = slurp.strip

          if @params.key?(:hash) && slurp[0] == '#'
            opset.push @params[:hash]
            opset.push slurp[1..slurp.length]
            return Op::HAS
          end

          slugs = slurp.split(/[<>:]/)

          return fallback(opset, slurp) if slugs.length < 2

          prefix = slugs[0]
          separator = slurp[prefix.length...(prefix.length + 1)].to_sym
          suffex = slurp[(prefix.length + 1)...slurp.length].strip

          prefix = prefix.downcase.to_sym

          # Self-based tags
          return Op::MY if check_pre(opset, :my, prefix, suffex, nil)
          # Boolean set operators
          return Op::EQUAL if check_pre(opset, :is, prefix, suffex, true)
          # User-based tags
          return Op::MY if check_post(opset, :by, prefix, suffex)
          # Greater than, less than, or equals
          return Op::CHAR_OP_LOOKUP[separator] if check_post(opset, :range_fields, prefix, suffex)
          # Tag-based queries
          return Op::HAS if check_post(opset, :has, prefix, suffex)
          # Only equals
          return Op::TEXT_EQUAL if check_post(opset, :fields, prefix, suffex)

          fallback(opset, slurp)
        end

        def fallback(opset, slugs)
          return @default_func.call(self, opset, slugs) if @default_func
          opset.push :tags
          opset.push slugs
          Op::HAS
        end

        def pre_recognises_prefix?(group, prefix, suffex)
          prefix == group && @params.key?(group) && @params[group].key?(suffex)
        end

        def post_recognises_prefix?(group, prefix)
          @params.key?(group) && @params[group].key?(prefix)
        end

        def check_pre(opset, group, prefix, suffex, value)
          suffex = suffex.to_sym
          if pre_recognises_prefix?(group, prefix, suffex)
            opset.push @params[group][suffex] # the field to check
            opset.push value                  # the value
            true
          end
        end

        def check_post(opset, group, prefix, suffex)
          if post_recognises_prefix?(group, prefix)
            opset.push @params[group][prefix] # the field to check
            opset.push suffex                 # the value to check against
            true
          end
        end
      end
    end
  end
end
