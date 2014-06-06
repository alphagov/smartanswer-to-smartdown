require 'pathname'
require 'multiple_choice_question'
require 'flow_parser'

describe "parsing a multiple_choice question" do
  def indent(text, num_spaces)
    text.gsub(/^/, " " * num_spaces)
  end

  let(:flow_name) { "example" }
  let(:yaml) {
    {"en-GB" => {"flow" => {"example" => translation_data}}}.to_yaml
  }
  let(:translation_data) { nil }

  let(:ruby) { <<RUBY
    multiple_choice(:question) { option :opt1 }
RUBY
  }
  let(:parser) {
    FlowParser.new(flow_name, ruby, yaml)
  }

  subject(:question) { parser.questions.first }

  let(:option_label) { "LABEL1" }

  describe "extracting options" do
    context "option label absent from translations" do
      let(:translation_data) { nil }

      it "uses the option name as the label" do
        expect(question.options.first.label).to eq("opt1")
      end
    end

    context "option label defined at node-level in translations" do
      let(:translation_data) { {"options" => {"opt1" => option_label}} }

      it "gets option label" do
        expect(question.options.first.label).to eq(option_label)
      end
    end

    context "option label overridden at question-level" do
      let(:translation_data) {
        {
          "options" => {"opt1" => "will be overridden"},
          "question" => {"options" => {"opt1" => option_label}}
        }
      }

      it "gets option label" do
        expect(question.options.first.label).to eq(option_label)
      end
    end
  end

  describe "extracting next node rules" do
    subject(:next_node_rules) { question.next_node_rules }

    context "option with next node defined" do
      let(:ruby) { "multiple_choice(:question) { option :a => :outcome1 }" }

      it { should eq([Rule.new(:outcome1, Predicate::Equality.new("question", "a"))]) }
    end

    context "option without next node defined" do
      let(:ruby) { "multiple_choice(:question) { option :a }" }

      it { should eq([]) }
    end

    context "combination of option with and without next node defined" do
      let(:ruby) { <<-RUBY
        multiple_choice(:question) {
          option :opt1 => :outcome1
          option :opt2
        }
        RUBY
      }

      it { should eq([Rule.new(:outcome1, Predicate::Equality.new("question", "opt1"))]) }
    end

    context "option with next_node_if" do
      subject { question.next_node_rules.first.predicate }
      let(:ruby) { %Q[multiple_choice(:question) { next_node_if(:outcome1, #{predicate}) }] }

      context 'responded_with("opt1") predicate' do
        let(:predicate) { %{responded_with("opt1")} }
        it { should eq(Predicate::Equality.new("question", "opt1")) }
      end

      context 'variable_matches predicate' do
        let(:predicate) { %{variable_matches(:my_var, "opt1")} }
        it { should eq(Predicate::Equality.new("my_var", "opt1")) }
      end
    end
  end
end
