require 'model/conditional_phrase'

module Parser
  class NewPhraseListTransform < Parser::Transform
    def pattern
      Q? { s(:call, s(:const, :PhraseList), :new, ___ % "args") }
    end

    def transform(sexp, match)
      s(*match["args"].map {|a| phrase_sym(a) }.compact.map do |phrase_sym|
        Model::ConditionalPhrase.new(phrase_sym)
      end)
    end

  private
    def phrase_sym(arg_sexp)
      case arg_sexp.first
      when :lit
        arg_sexp[1]
      when :dsym
        arg_sexp.rest
      else
        raise "Unrecognised argument to phrase list: '#{arg_sexp.inspect}'"
      end
    end
  end
end
