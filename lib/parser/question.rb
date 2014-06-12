require 'sexp_path_dsl'
require 'model/question'
require 'model/multiple_choice_question'
require 'parser/question_transform'
require 'parser/multiple_choice_question_transform'
require 'parser/next_node_rules_transform'
require 'parser/option_transform'
require 'parser/outer_block_remover'

module Parser

  class Question
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def parse(sexp)
      transform.apply(sexp)
    end

    def transform
      NextNodeRulesTransform.new <<
        OptionTransform.new(translations) <<
        QuestionTransform.new(translations) <<
        MultipleChoiceQuestionTransform.new(translations) <<
        OuterBlockRemover.new
    end
  end
end
