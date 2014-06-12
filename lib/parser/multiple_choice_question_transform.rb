require 'parser/question_transform'
require 'model/rule'
require 'model/option'
require 'model/multiple_choice_question'

module Parser
  class MultipleChoiceQuestionTransform < QuestionTransform
    def question_types
      [:multiple_choice]
    end

    def transform(sexp)
      Model::MultipleChoiceQuestion.new(
        bound_options,
        @match_data['type'],
        @match_data['name'],
        @match_data['args'],
        @match_data['body'],
        next_node_rules,
        translations
      )
    end

    def unbound_options
      sexp_select(@match_data['body']) { |elem| elem.is_a?(OptionTransform::UnboundOption) }
    end

    def bound_options
      unbound_options
        .map do |unbound_option|
          Model::Option.new(
            unbound_option.name,
            option_title(@match_data['name'], unbound_option.name),
            unbound_option.next_node
          )
        end
    end

    def next_node_rules
      next_node_rules_from_options + super
    end

  private
    def option_title(question_name, option_name)
      translations.get("#{question_name}.options.#{option_name}") ||
        translations.get("options.#{option_name}") ||
        option_name.to_s
    end

    def next_node_rules_from_options
      unbound_options.select { |o| o.next_node }.map do |o|
        Model::Rule.new(o.next_node, Predicate::Equality.new(response_variable_name, o.name.to_s))
      end
    end
  end
end
