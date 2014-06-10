require 'parser/next_node_rules'

describe Parser::NextNodeRules do
  let(:ruby) { %Q[next_node_if(:outcome1, #{predicate})] }
  let(:response_variable_name) { "question" }
  let(:parsed) { parse_ruby(ruby) }

  subject(:rules) do
    described_class.new(response_variable_name).extract(parsed)
  end

  describe "extracting next node rules" do
    context "rule defined using next_node_if" do
      let(:ruby) { %Q[next_node_if(:outcome, #{predicate})] }

      context 'responded_with("opt1") predicate' do
        let(:predicate) { %{responded_with("opt1")} }
        it { should eq([Rule.new(:outcome, Predicate::Equality.new("question", "opt1"))]) }
      end

      context 'responded_with(%w{})' do
        let(:predicate) { %{responded_with(%w{a b})} }
        it { should eq([Rule.new(:outcome, Predicate::SetInclusion.new("question", %w{a b}))]) }
      end

      context 'variable_matches predicate' do
        let(:predicate) { %{variable_matches(:my_var, "opt1")} }
        it { should eq([Rule.new(:outcome, Predicate::Equality.new("my_var", "opt1"))]) }
      end

      context 'variable_matches(%w{}) predicate' do
        let(:predicate) { %{variable_matches(:my_var, %w{a b})} }
        it { should eq([Rule.new(:outcome, Predicate::SetInclusion.new("my_var", %w{a b}))]) }
      end
    end

    context "option with on_condition" do
      let(:predicate1) { 'variable_matches(:a, "apple")' }
      let(:predicate2) { 'responded_with("opt1")' }
      let(:ruby) { %Q[
        on_condition(#{predicate1}) {
          next_node_if(:outcome1, #{predicate2})
        }
      ]
      }
      it {
        should eq(
          [
            OnConditionRule.new(
              Predicate::Equality.new("a", "apple"),
              [
                Rule.new(:outcome1,
                  Predicate::Equality.new("question", "opt1")
                )
              ]
            )
          ]
        )
      }
    end
  end
end
