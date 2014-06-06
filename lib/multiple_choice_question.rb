require "question"
require "rule"
require "predicate/equality"

class MultipleChoiceQuestion < Question
  def options
    q_option = Q? { s(:call, nil, :option, any(
      s(:lit, atom % "option_name"),
      s(:hash, s(:lit, atom % "option_name"), s(:lit, atom % "next_node")))) }

    (body / q_option).map do |match|
      Option.new(match["option_name"], option_title(match["option_name"]), match["next_node"])
    end
  end

  def option_title(option_name)
    translations.get("#{name}.options.#{option_name}") ||
      translations.get("options.#{option_name}") ||
      option_name.to_s
  end

  def next_node_rules
    options.select { |o| o.next_node }.map do |o|
      Rule.new(o.next_node, Predicate::Equality.new(response_variable_name, o.name.to_s))
    end
  end

  class Option < Struct.new(:name, :label, :next_node); end
end
