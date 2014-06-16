require 'predicate/raw'

module Parser
  class ConditionalTransform < Parser::Transform
    def pattern
      Q? {
        s(:if,
          wild % "predicate",
          wild % "true_sexp",
          nil)
      }
    end

    def transform(sexp, match)
      predicate = Predicate::Raw.new(match["predicate"])
      array_of_conditional_phrases = sexp_select(s(match["true_sexp"])) { |elem| elem.is_a? Model::ConditionalPhrase}.map do |phrase|
        phrase.predicates << predicate
        phrase
      end
      s(*array_of_conditional_phrases)
    end
  end
end
