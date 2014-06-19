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
      precalculations = SexpWalker.select_type(match["body"], Model::Precalculation)
      Model::OutcomeBlock.new(match["outcome_name"], translations, precalculations)
    end
  end
end
