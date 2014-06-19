require 'parser/transform'
require 'parser/outcome_block_transform'
require 'parser/precalculation_transform'
require 'parser/conditional_transform'
require 'parser/phrase_push_transform'
require 'parser/new_phrase_list_transform'

module Parser
  class OutcomeBlockTransformChain < Parser::TransformChain
    attr_reader :translations

    def initialize(translations)
      @translations = translations
      super(
        Parser::PhrasePushTransform.new,
        Parser::NewPhraseListTransform.new,
        Parser::ConditionalTransform.new,
        Parser::PrecalculationTransform.new,
        Parser::OutcomeBlockTransform.new(translations)
      )
    end
  end
end
