require 'parser/transform'

module Parser
  class OuterBlockRemover < Parser::Transform
    def match?(sexp)
      sexp.is_a?(Sexp) && sexp.head == :block
    end

    def transform(sexp)
      sexp.rest
    end
  end
end
