require 'parser/transform'

module Parser
  class Unparser < TransformChain
    def initialize
      super(
        LiteralTransform.new,
        DynamicStringTransform.new,
        StringTransform.new,
        BooleanTransform.new,
        CallTransform.new
      )
    end

    class LiteralTransform < Parser::SexpTransform
      def sexp_match?(sexp)
        sexp.first == :lit
      end

      def transform(sexp)
        sexp[1].to_s
      end
    end

    class StringTransform < Parser::SexpTransform
      def sexp_match?(sexp)
        sexp.first == :str
      end

      def transform(sexp)
        "'#{sexp[1].to_s}'"
      end
    end

    class DynamicStringTransform < Parser::SexpTransform
      def sexp_match?(sexp)
        sexp.first == :dstr
      end

      def transform(sexp)
        inner = (BareStrTransform.new << EvstrTransform.new).apply(sexp.rest)
        '"' + inner.join("") + '"'
      end

      class EvstrTransform < Parser::SexpTransform
        def sexp_match?(sexp)
          sexp.first == :evstr
        end

        def transform(sexp)
          '#{' + Unparser.new.apply(sexp.rest).join("") + '}'
        end
      end

      class BareStrTransform < Parser::SexpTransform
        def sexp_match?(sexp)
          sexp.first == :str
        end

        def transform(sexp)
          sexp[1]
        end
      end
    end

    class BooleanTransform < Parser::SexpTransform
      def sexp_match?(sexp)
        [:true, :false].include?(sexp.first)
      end

      def transform(sexp)
        sexp.first.to_s
      end
    end

    class CallTransform < Parser::SexpTransform
      def sexp_match?(sexp)
        sexp.first == :call
      end

      def transform(sexp)
        _, receiver, method_name, *args = sexp
        if inline?(method_name)
          "#{receiver} #{method_name} #{args.join(", ")}"
        else
          text = ""
          text << "#{receiver}." unless receiver.nil?
          text << method_name.to_s
          text << "(#{args.join(", ")})" if args.any?
          text
        end
      end

    private
      def inline?(method_name)
        [:==, :+, :-].include?(method_name)
      end
    end
  end
end
