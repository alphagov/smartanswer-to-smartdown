require 'model/precalculation'

module Parser
  class PrecalculationTransform < Parser::Transform
    def pattern
      Q? {
        s(:iter,
          s(:call, nil, :precalculate, s(:lit, atom % "name")),
          s(:args), ___ % "conditional_phrases"
        )
      }
    end

    def transform(sexp, match)
      conditional_phrases = sexp_select(sexp) {|s| s.is_a?(Model::ConditionalPhrase)}
      Model::Precalculation.new(match["name"], conditional_phrases)
    end
  end
end
