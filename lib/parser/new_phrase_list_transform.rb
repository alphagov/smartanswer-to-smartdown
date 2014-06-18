require 'model/conditional_phrase'

module Parser
  class NewPhraseListTransform < Parser::Transform
    def pattern
      Q? {
        s(:call, s(:const, :PhraseList), :new, ___ % "args")
      }
    end

    def transform(sexp, match)
      s(*match["args"].map {|a| phrase_sym(a) }.compact.map do |phrase_sym|
        Model::ConditionalPhrase.new(phrase_sym)
      end)
    end

  private
    def phrase_sym(arg_sexp)
      arg_sexp[0] == :lit ? arg_sexp[1] : nil
    end
  end
end
