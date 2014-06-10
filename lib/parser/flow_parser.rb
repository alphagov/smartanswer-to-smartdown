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
      Question.match_all(parse_tree) do |question_type, question_sexp|
        case question_type
        when :multiple_choice
          MultipleChoiceQuestion.new(translations, question_sexp)
        else
          Question.new(translations, question_sexp)
        end
      end
    end

    def build_outcome(match)

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
