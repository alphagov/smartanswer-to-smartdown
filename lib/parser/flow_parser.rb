require 'ruby_parser'
require 'sexp_path'

require 'parser/translations'
require 'sexp_path_dsl'
require 'multiple_choice_question'
require 'outcome'

module Parser
  class FlowParser
    include SexpPathDsl

    def initialize(name, ruby, yaml)
      @name = name
      @ruby = ruby
      @yaml = yaml
    end

    def self.parse(flow_name, ruby, yaml)
      FlowParser.new(flow_name, ruby, yaml)
    end

    def questions
      @questions ||= extract_questions
    end

    def outcomes
      @outcomes ||= extract_outcomes
    end

    def coversheet
      {
        start_with: questions.first.name,
        satisfies_need: satisfies_need,
        meta_description: meta_description
      }.reject { |k,v| v.nil? }
    end

    def title
      translations.get("title")
    end

    def body
      translations.get("body")
    end

    def satisfies_need
      match = find_one(Q? { s(:call, nil, :satisfies_need, s(:str, atom % "need_id")) })
      match && match['need_id']
    end

    def meta_description
      translations.get("meta.description")
    end

  private
    QUESTION_METHODS = [
      :multiple_choice,
      :country_select,
      :date_question,
      :optional_date,
      :value_question,
      :money_question,
      :salary_question,
      :checkbox_question
    ]

    def find(query)
      parse_tree / query
    end

    def find_one(query)
      matches = parse_tree / query
      matches.any? ? matches.first : nil
    end

    def parse_tree
      @parse_tree ||= RubyParser.for_current_ruby.parse(@ruby)
    end

    def extract_questions
      (parse_tree / question_query).map { |match| build_question(match) }
    end

    def build_question(match)
      question_type = match["question_method"]
      question_args = match["question_args"]
      question_body = match["body"]
      case question_type
      when :multiple_choice
        MultipleChoiceQuestion.new(translations, question_args, question_body)
      else
        Question.new(translations, question_args, question_body)
      end
    end

    def build_outcome(match)

    end

    def question_query
      Q? {
        s(:iter,
          s(:call, nil, m(%r{#{QUESTION_METHODS.join("|")}}) % 'question_method', ___ % "question_args"),
          s(:args, ___ % "block_args"),
          ___ % "body")
      }
    end

    def translations
      @translations ||= Translations.new(@name, @yaml)
    end

    def outcome_query
      Q? {
        s(:call, nil, :outcome, s(:lit, atom % "outcome_name"))
      }
    end

    def extract_outcomes
      (parse_tree / outcome_query).map do |match|
        Outcome.new(translations, match["outcome_name"])
      end
    end

  end
end
