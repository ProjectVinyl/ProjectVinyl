require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class Index
      def initialize(params = {})
        @params = params
      end
      VIDEO_INDEX_PARAMS = Index.new({
        my: {
          upvotes: :likes,
          downvotes: :dislikes,
          uploads: :user_id
        },
        by: {
          uploader: :user_id,
          upvoted_by: :likes,
          downvoted_by: :dislikes
        },
        is: {
          audio: :audio_only,
          hidden: :hidden
        },
        fields: {
          title: :title,
          source: :source,
          aspect: :aspect
        },
        range_fields: {
          length: :length,
          width: :width,
          height: :height,
          score: :score,
          size: :size
        }
      })

      CHAR_OP_LOOKUP = {
        ':': ProjectVinyl::ElasticSearch::Op::EQUAL,
        '>': ProjectVinyl::ElasticSearch::Op::GREATER_THAN,
        '<': ProjectVinyl::ElasticSearch::Op::LESS_THAN
      }.freeze

      def slurp_tags(opset, slurp)
        slurp = slurp.strip

        # Self-based tags
        if slurp.index('my:') == 0
          value = slurp.sub('my:', '').strip.downcase.to_sym

          if @params[:my].key?(value)
            opset.push @params[:my][value]
            opset.push 'nil'
            return Op::MY
          end
        end

        # Boolean set operators
        if slurp.index('is:') == 0
          value = slurp.sub('is:', '').strip.downcase.to_sym

          if @params[:is].key?(value)
            opset.push @params[:is][value]       # the field to check
            opset.push true                      # the value
            return Op::EQUAL                     # operator (IS)
          end
        end

        # User-based tags
        if (field = @params[:by].keys.find {|key| slurp.index(key.to_s + ':') == 0})
          opset.push @params[:by][field]             # the field to check
          opset.push slurp.sub(field.to_s + ':', '') # the user name/id
          return Op::MY                              # operator (MY)
        end

        # Greater than, less than, or equals
        if (field = @params[:range_fields].keys.find {|key| slurp.index(key.to_s) == 0})
          slug = slurp.sub(field.to_s, '')
          if (op = CHAR_OP_LOOKUP.keys.find {|key| slug.index(key.to_s) == 0})
            opset.push @params[:range_fields][field]  # the field to check
            opset.push slug.sub(op.to_s, '')          # the value to check against
            return CHAR_OP_LOOKUP[op]                 # operator (LESS_THAN, EQUAL, GREATER_THAN)
          end
        end

        # Only equals
        if (field = @params[:fields].keys.find {|key| slurp.index(key.to_s + ':') == 0})
          opset.push @params[:fields][field]   # the field to check
          opset.push slurp.sub(field.to_s + ':', '') # the value to check against
          return Op::TEXT_EQUAL                # operator (TEXT_EQUAL)
        end

        slurp
      end
    end
  end
end
