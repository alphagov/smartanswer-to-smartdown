require "parser/question"
require "model/rule"
require "model/on_condition_rule"
require "model/option"
require "parser/next_node_rules"
require "predicate/equality"
require "predicate/set_inclusion"
require "predicate/conjunction"

module Parser
  class MultipleChoiceQuestionBuilder
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def build(match)
      Model::MultipleChoiceQuestion.new(
        options(match['name'], match['body']),
        match['type'],
        match['name'],
        match['args'],
        match['body'],
        translations
      )
    end

    def options(question_name, body_sexp)
      (body_sexp / q_option).map do |match|
        next_node = if (match["option_arg"] / Q? { s(:hash, s(:lit, _), s(:lit, _)) }).any?
          match["next_node"]
        else
          nil
        end
        Model::Option.new(
          match["option_name"],
          option_title(question_name, match["option_name"]),
          next_node
        )
      end
    end

    def option_title(question_name, option_name)
      translations.get("#{question_name}.options.#{option_name}") ||
        translations.get("options.#{option_name}") ||
        option_name.to_s
    end

    def next_node_rules
      next_node_rules_from_options +
        Parser::NextNodeRules.new(response_variable_name).extract(body)
    end

  private
    def next_node_rules_from_options
      options.select { |o| o.next_node }.map do |o|
        Rule.new(o.next_node, Predicate::Equality.new(response_variable_name, o.name.to_s))
      end
    end

    def q_option
      Q? {
        s(:call, nil, :option,
          any(
            s(:lit, atom % "option_name"),
            s(:hash, s(:lit, atom % "option_name"), s(:lit, atom % "next_node"))
          ) % "option_arg"
        )
      }
    end

  end
end
