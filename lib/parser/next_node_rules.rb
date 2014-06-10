require 'sexp_path_dsl'
require 'predicate/equality'
require 'predicate/set_inclusion'
require 'predicate/conjunction'
require 'model/rule'
require 'model/on_condition_rule'

module Parser
  class NextNodeRules
    include SexpPathDsl

    attr_reader :response_variable_name

    def initialize(response_variable_name)
      @response_variable_name = response_variable_name
    end

    def extract(body_sexp)
      if body_sexp.node_type == :block
        body_sexp.rest.inject([]) do |sexp, rules|
          rules + extract(sexp)
        end
      else
        [extract_one(body_sexp)].compact
      end
    end

    def extract_one(sexp)
      match = {}
      if q_next_node_if.satisfy?(sexp, match)
        Rule.new(match["next_node"], *build_predicates(match["predicate_list"]))
      elsif q_on_condition.satisfy?(sexp, match)
        OnConditionRule.new(
          build_predicates(match["predicate_list"]).first,
          extract(match["body"].first)
        )
      else
        nil
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

    def q_next_node_if
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
end
