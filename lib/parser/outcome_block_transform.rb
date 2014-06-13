require 'parser/transform'
require 'model/outcome_block'

module Parser
  class OutcomeBlockTransform < Parser::Transform
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def pattern
      Q? { s(:iter, s(:call, nil, :outcome, s(:lit, atom % "outcome_name")), s(:args), ___ % "body")}
    end

    def transform(sexp, match)
      Model::OutcomeBlock.new(match["outcome_name"], translations, match["body"].to_a)
    end
  end
end
