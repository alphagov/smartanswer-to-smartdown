require 'model/outcome'

module Parser
  class OutcomeTransform < Parser::Transform
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def pattern
      Q? { s(:call, nil, :outcome, s(:lit, atom % "outcome_name")) }
    end

    def transform(sexp, match)
      Model::Outcome.new(match["outcome_name"], translations)
    end
  end
end
