require 'parser/transform'

module Parser
  class QuestionTransform < Parser::Transform
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def question_types
      [
        :country_select,
        :date_question,
        :optional_date,
        :value_question,
        :money_question,
        :salary_question,
        :checkbox_question
      ]
    end

    def pattern
      question_types = self.question_types

      Q? {
        s(:iter,
            s(:call, nil,
              m(%r{#{question_types.join("|")}}) % 'type',
              s(:lit, atom % "name"),
              ___ % "args"),
            s(:args, ___ % "block_args"),
            ___ % "body")
      }
    end

    def transform(sexp)
      Model::Question.new(
        @match_data['type'],
        @match_data['name'],
        @match_data['args'],
        @match_data['body'],
        translations
      )
    end

    def response_variable_name
      @match_data['name'].to_s.gsub(/\?$/, '')
    end
  end
end
