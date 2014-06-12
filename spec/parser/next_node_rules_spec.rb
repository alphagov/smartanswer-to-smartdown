require 'parser/question'
require 'model/rule'

describe "parsing next node rules" do
  let(:sexp) { parse_ruby(ruby) }

  let(:translations) { double(:translations, get: "no translation") }
  let(:parser) { Parser::Question.new(translations) }
  let(:question) { parser.parse(sexp) }
  subject(:next_node_rules) { question.next_node_rules }

  describe "extracting next node rules" do
    context "rule defined using next_node_if" do
      let(:ruby) { %Q[multiple_choice(:question) { next_node_if(:outcome, #{predicate}) }] }

      context 'responded_with("opt1") predicate' do
        let(:predicate) { %{responded_with("opt1")} }
        it { should eq([Model::Rule.new(:outcome, Predicate::Equality.new(nil, "opt1"))]) }
      end

      context 'responded_with(%w{})' do
        let(:predicate) { %{responded_with(%w{a b})} }
        it { should eq([Model::Rule.new(:outcome, Predicate::SetInclusion.new(nil, %w{a b}))]) }
      end

      context 'variable_matches predicate' do
        let(:predicate) { %{variable_matches(:my_var, "opt1")} }
        it { should eq([Model::Rule.new(:outcome, Predicate::Equality.new("my_var", "opt1"))]) }
      end

      context 'variable_matches(%w{}) predicate' do
        let(:predicate) { %{variable_matches(:my_var, %w{a b})} }
        it { should eq([Model::Rule.new(:outcome, Predicate::SetInclusion.new("my_var", %w{a b}))]) }
      end
    end

    context "option with on_condition" do
      let(:predicate1) { 'variable_matches(:a, "apple")' }
      let(:predicate2) { 'responded_with("opt1")' }
      let(:ruby) { %Q[
        multiple_choice(:question) {
          on_condition(#{predicate1}) {
            next_node_if(:outcome1, #{predicate2})
          }
        }
      ]
      }
      it {
        should eq(
          [
            Model::OnConditionRule.new(
              Predicate::Equality.new("a", "apple"),
              [
                Model::Rule.new(:outcome1,
                  Predicate::Equality.new(nil, "opt1")
                )
              ]
            )
          ]
        )
      }
    end
  end
end
