require 'sexp_path'
require 'parser/sexp_walker'

module Parser
  class TransformChain
    def initialize(*chain)
      @chain = chain
    end

    def apply(sexp)
      @chain.inject(sexp) do |sexp, transform|
        transform.apply(sexp)
      end
    end

    def <<(other)
      @chain << other
      self
    end
  end

  class Transform
    def match?(sexp)
      @match_data = pattern.satisfy?(sexp)
      !! @match_data
    end

    def pattern
      raise "Abstract class: no sexp_path pattern defined"
    end

    def transform(sexp)
      raise "Abstract class: no transform defined"
    end

    def apply(sexp)
      apply_inner(s(sexp)).first
    end

    def <<(other)
      TransformChain.new(self, other)
    end

    def walk_sexp(sexp, &block)
      Parser::SexpWalker.walk(sexp, &block)
    end

    def sexp_select(sexp, &block)
      Parser::SexpWalker.select(sexp, &block)
    end

  private
    def Q?(&pattern_definition)
      SexpPath::SexpQueryBuilder.do(&pattern_definition)
    end

    def apply_inner(sexp)
      array = sexp.map do |elem|
        if elem.is_a?(Sexp)
          elem = apply_inner(elem)
        end

        if match?(elem)
          method(:transform).arity == 1 ? transform(elem) : transform(elem, @match_data)
        else
          elem
        end
      end
      s(*array)
    end
  end

  class SexpTransform < Transform
    def match?(sexp)
      sexp.is_a?(Sexp) && sexp_match?(sexp)
    end
  end
end
