require 'pathname'
require 'multiple_choice_question'
require 'flow_parser'

describe MultipleChoiceQuestion do
  def indent(text, num_spaces)
    text.gsub(/^/, " " * num_spaces)
  end

  let(:flow_name) { "example" }
  let(:yaml) {
    {"en-GB" => {"flow" => {"example" => yaml_inner}}}.to_yaml
  }

  let(:ruby) { <<RUBY
    multiple_choice(:question) { option :opt1 }
RUBY
  }
  let(:parser) {
    FlowParser.new(flow_name, ruby, yaml)
  }

  subject(:question) { parser.questions.first }

  let(:option_label) { "LABEL1" }

  context "option label undefined" do
    let(:yaml_inner) { nil }

    it "uses the option name as the label" do
      expect(question.options.first.label).to eq("opt1")
    end
  end

  context "option label defined at node-level" do
    let(:yaml_inner) { {"options" => {"opt1" => option_label}} }

    it "gets option label" do
      expect(question.options.first.label).to eq(option_label)
    end
  end

  context "option label overridden at question-level" do
    let(:yaml_inner) {
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
