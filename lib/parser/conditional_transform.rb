require 'predicate/raw'

module Parser
  class ConditionalTransform < Parser::Transform
    def pattern
      Q? {
        s(:if,
          wild % "predicate",
          wild % "true_sexp",
          wild % "false_sexp")
      }
    end

    def transform(sexp, match)
      predicate = Predicate::Raw.new(match["predicate"])
      negated_predicate = Predicate::Raw.new(s(:call, match["predicate"], :!))
      true_phrases = sexp_select(s(match["true_sexp"])) { |elem| elem.is_a? Model::ConditionalPhrase }
      false_phrases = sexp_select(s(match["false_sexp"])) { |elem| elem.is_a? Model::ConditionalPhrase }
      true_phrases.each { |p| p.predicates << predicate }
      false_phrases.each { |p| p.predicates << negated_predicate }
      s(*true_phrases, *false_phrases)
    end
  end
end
