require 'pathname'
require 'parser/translations'
require 'parser/question'
require 'model/rule'

describe "parsing multiple choice question" do
  let(:flow_name) { "example" }
  let(:translation_data) { nil }
  let(:translation_yaml) {
    {"en-GB" => {"flow" => {flow_name => translation_data}}}.to_yaml
  }
  let(:translations) { Parser::Translations.new(flow_name, translation_yaml) }

  let(:ruby) { %Q{ multiple_choice(:question) {option :opt1} } }
  let(:sexp) { parse_ruby(ruby) }

  let(:parser) { Parser::Question.new(translations) }
  subject(:question) { parser.parse(sexp) }

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

  describe "extracting next node rules from options" do
    subject(:next_node_rules) { question.next_node_rules }

    context "option with next node defined" do
      let(:ruby) { "multiple_choice(:question) { option :a => :outcome1 }" }

      it { should eq([Model::Rule.new(:outcome1, Predicate::Equality.new("question", "a"))]) }
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

      it { should eq([Model::Rule.new(:outcome1, Predicate::Equality.new("question", "opt1"))]) }
    end
  end
end
