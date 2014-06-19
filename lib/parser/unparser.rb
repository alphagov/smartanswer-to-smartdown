require 'ruby2ruby'

module Parser
  class Unparser
    def self.unparse(sexp)
      Ruby2Ruby.new.process(deep_clone_sexp(sexp))
    end

  private
    def self.deep_clone_sexp(sexp)
      case sexp
      when Sexp
        s(*sexp.map { |child| deep_clone_sexp(child) })
      when NilClass, Symbol, Fixnum
        sexp
      else
        sexp.dup
      end
    end
  end
end
