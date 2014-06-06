require "question"
require "rule"
require "predicate/equality"

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
    next_node_rules_from_options + next_node_rules_from_next_node_ifs
  end

private
  def next_node_rules_from_options
    options.select { |o| o.next_node }.map do |o|
      Rule.new(o.next_node, Predicate::Equality.new(response_variable_name, o.name.to_s))
    end
  end

  def next_node_rules_from_next_node_ifs
    next_node_ifs
  end

  def next_node_ifs
    q = Q? {
      s(:call, nil, :next_node_if,
        s(:lit, atom % "next_node"),
        ___ % "predicate_list"
      )
    }

    (body / q).map do |match|
      Rule.new(match["next_node"], *build_predicate(match["predicate_list"]))
    end
  end

  def build_predicate(predicate_sexp)
    predicate_sexp.map do |predicate|
      match = {}
      rw = Q? { s(:call, nil, :responded_with, s(:str, atom % "expected_value")) }
      vm = Q? { s(:call, nil, :variable_matches,
        s(:lit, atom % "var_name"),
        s(:str, atom % "expected_value"))
      }
      if rw.satisfy?(predicate, match)
        Predicate::Equality.new(response_variable_name, match["expected_value"])
      elsif vm.satisfy?(predicate, match)
        Predicate::Equality.new(match["var_name"].to_s, match["expected_value"])
      end
    end
  end

  class Option < Struct.new(:name, :label, :next_node); end
end
