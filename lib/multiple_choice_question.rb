require "question"
require "rule"
require "on_condition_rule"
require "predicate/equality"
require "predicate/set_inclusion"
require "predicate/conjunction"

class MultipleChoiceQuestion < Question
  def options
    q_option = Q? {
      s(:call, nil, :option,
        any(
          s(:lit, atom % "option_name"),
          s(:hash, s(:lit, atom % "option_name"), s(:lit, atom % "next_node"))
        ) % "option_arg"
      )
    }

    (body / q_option).map do |match|
      next_node = if (match["option_arg"] / Q? { s(:hash, s(:lit, _), s(:lit, _)) }).any?
        match["next_node"]
      else
        nil
      end
      Option.new(match["option_name"], option_title(match["option_name"]), next_node)
    end
  end

  def option_title(option_name)
    translations.get("#{name}.options.#{option_name}") ||
      translations.get("options.#{option_name}") ||
      option_name.to_s
  end

  def next_node_rules
    next_node_rules_from_options +
      NextNodeIfExtractor.new(response_variable_name).extract(body)
  end

private
  def next_node_rules_from_options
    options.select { |o| o.next_node }.map do |o|
      Rule.new(o.next_node, Predicate::Equality.new(response_variable_name, o.name.to_s))
    end
  end

  class NextNodeIfExtractor
    attr_reader :response_variable_name

    def initialize(response_variable_name)
      @response_variable_name = response_variable_name
    end

    def extract(body = @body)
      if body.size == 1 && body.first.node_type == :block
        extract(body.first.rest)
      else
        body.map do |sexp|
          match = {}
          if q_next_node.satisfy?(sexp, match)
            Rule.new(match["next_node"], *build_predicates(match["predicate_list"]))
          elsif q_on_condition.satisfy?(sexp, match)
            OnConditionRule.new(
              build_predicates(match["predicate_list"]).first,
              extract(match["body"])
            )
          else
            nil
          end
        end.compact
      end
    end

  private
    def build_predicates(predicate_sexp)
      predicate_sexp.map do |predicate|
        rw = Q? { s(:call, nil, :responded_with, s(:str, atom % "expected_value")) }
        rwa = Q? { s(:call, nil, :responded_with, s(:array, ___ % "expected_values")) }
        vm = Q? { s(:call, nil, :variable_matches,
          s(:lit, atom % "var_name"),
          s(:str, atom % "expected_value"))
        }
        vma = Q? {
          s(:call, nil, :variable_matches,
            s(:lit, atom % "var_name"),
            s(:array, ___ % "expected_values")
          )
        }
        match = {}
        if rw.satisfy?(predicate, match)
          Predicate::Equality.new(response_variable_name, match["expected_value"])
        elsif rwa.satisfy?(predicate, match)
          Predicate::SetInclusion.new(response_variable_name, convert_atoms(match["expected_values"]))
        elsif vm.satisfy?(predicate, match)
          Predicate::Equality.new(match["var_name"].to_s, match["expected_value"])
        elsif vma.satisfy?(predicate, match)
          Predicate::SetInclusion.new(match["var_name"].to_s, convert_atoms(match["expected_values"]))
        end
      end
    end

    def convert_atoms(atom_list)
      atom_list.map do |a|
        matches = {}
        if (Q? { s(:str, atom % "s") }.satisfy?(a, matches))
          matches['s']
        end
      end
    end

    def q_next_node
      Q? {
        s(:call, nil, :next_node_if,
          s(:lit, atom % "next_node"),
          ___ % "predicate_list"
        )
      }
    end

    def q_on_condition
      Q? {
        s(:iter,
          s(:call, nil, :on_condition, ___ % "predicate_list"),
          s(:args, ___ % "block_args"),
          ___ % "body"
        )
      }
    end
  end

  class Option < Struct.new(:name, :label, :next_node); end
end
