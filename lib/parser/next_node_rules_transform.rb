require 'sexp_path_dsl'
require 'predicate/equality'
require 'predicate/set_inclusion'
require 'predicate/conjunction'
require 'model/rule'
require 'model/on_condition_rule'
require 'delegate'

module Parser
  class NextNodeIfTransform < Parser::Transform
    def pattern
      Q? {
        s(:call, nil, :next_node_if,
          s(:lit, atom % "next_node"),
          ___ % "predicate_list"
        )
      }
    end

    def transform(sexp, match)
      Model::Rule.new(match["next_node"], *match["predicate_list"])
    end
  end

  class OnConditionTransform < Parser::Transform
    def pattern
      Q? {
        s(:iter,
          s(:call, nil, :on_condition, ___ % "predicate_list"),
          s(:args, ___ % "block_args"),
          ___ % "body"
        )
      }
    end

    def transform(sexp, match)
      Model::OnConditionRule.new(
        match["predicate_list"].first,
        sexp_select(match["body"]) { |s| [Model::Rule, Model::OnConditionRule].any? {|r| s.is_a?(r)} }
      )
    end
  end

  class PredicateTransform < Parser::Transform
    def convert_atoms(atom_list)
      atom_list.map do |a|
        matches = {}
        if (Q? { s(:str, atom % "s") }.satisfy?(a, matches))
          matches['s']
        end
      end
    end
  end

  class RespondedWithSingularPredicate < PredicateTransform
    def pattern
      Q? { s(:call, nil, :responded_with, s(:str, atom % "expected_value")) }
    end

    def transform(sexp, match)
      Predicate::Equality.new(nil, match["expected_value"])
    end
  end

  class RespondedWithPluralPredicate < PredicateTransform
    def pattern
      Q? { s(:call, nil, :responded_with, s(:array, ___ % "expected_values")) }
    end

    def transform(sexp, match)
      Predicate::SetInclusion.new(nil, convert_atoms(match["expected_values"]))
    end
  end

  class VariableMatchesSingularPredicate < PredicateTransform
    def pattern
      Q? { s(:call, nil, :variable_matches,
        s(:lit, atom % "var_name"),
        s(:str, atom % "expected_value"))
      }
    end

    def transform(sexp, match)
      Predicate::Equality.new(match["var_name"].to_s, match["expected_value"])
    end
  end

  class VariableMatchesPluralPredicate < PredicateTransform
    def pattern
      Q? {
        s(:call, nil, :variable_matches,
          s(:lit, atom % "var_name"),
          s(:array, ___ % "expected_values")
        )
      }
    end

    def transform(sexp, match)
      Predicate::SetInclusion.new(match["var_name"].to_s, convert_atoms(match["expected_values"]))
    end
  end

  class NextNodeRulesTransform < Parser::TransformChain
    def initialize
      super(
        VariableMatchesPluralPredicate.new,
        VariableMatchesSingularPredicate.new,
        RespondedWithPluralPredicate.new,
        RespondedWithSingularPredicate.new,
        NextNodeIfTransform.new,
        OnConditionTransform.new
      )
    end
  end
end
