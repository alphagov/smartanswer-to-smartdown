require 'parser/transform'
require 'parser/sexp_walker'
require 'parser/question_transform'
require 'parser/multiple_choice_question_transform'
require 'parser/next_node_rules_transform'
require 'parser/option_transform'
require 'parser/outer_block_remover'

module Parser
  class Question < Parser::TransformChain
    def initialize(translations)
      super(
        NextNodeRulesTransform.new,
        OptionTransform.new(translations),
        QuestionTransform.new(translations),
        MultipleChoiceQuestionTransform.new(translations)
      )
    end

    def parse(sexp)
      apply(sexp)
    end
  end
end
