require 'sexp_path_dsl'
require 'model/question'
require 'model/multiple_choice_question'
require 'parser/multiple_choice_question_builder'

module Parser
  class Question
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def parse(sexp)
      match_all(sexp) do |type, match|
        case type
        when :multiple_choice
          Parser::MultipleChoiceQuestionBuilder.new(translations).build(match)
        else
          build_question(match)
        end
      end
    end

    def question_types
      [
        :multiple_choice,
        :country_select,
        :date_question,
        :optional_date,
        :value_question,
        :money_question,
        :salary_question,
        :checkbox_question
      ]
    end

  private
    def match_all(sexp, &block)
      (sexp / question_query).map do |match|
        yield match["type"], match
      end
    end

    def build_question(match)
      Model::Question.new(
        match['type'],
        match['name'],
        match['args'],
        match['body'],
        translations
      )
    end

    def question_query
      question_types = self.question_types
      SexpPath::SexpQueryBuilder.do {
        s(:iter,
          s(:call, nil,
            m(%r{#{question_types.join("|")}}) % 'type',
            s(:lit, atom % "name"),
            ___ % "args"),
          s(:args, ___ % "block_args"),
          ___ % "body")
      }
    end
  end
end
