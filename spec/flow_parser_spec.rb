require 'pathname'
require 'parser/flow_parser'

describe "FlowParser" do
  let(:fixtures) { Pathname.new("fixtures/unit").expand_path(File.dirname(__FILE__)) }
  let(:flow_name) { "example" }
  let(:flow_ruby) { File.read(fixtures + "#{flow_name}.rb") }
  let(:flow_yml) { File.read(fixtures + "#{flow_name}.yml") }

  subject(:parsed) {
    Parser::FlowParser.parse(flow_name, flow_ruby, flow_yml)
  }

  it "extracts the coversheet metadata" do
    expect(parsed.coversheet).to eq(
      meta_description: "You may need a visa to come to the UK to visit, study or work.",
      satisfies_need: "100982",
      start_with: :purpose_of_visit?
    )
  end

  it "extracts the title" do
    expect(parsed.title).to eq("Check if you need a UK visa")
  end

  it "extracts the body" do
    expect(parsed.body).to eq("You may need a visa to come to the UK to visit, study or work.\n")
  end

  it "extracts list of question nodes" do
    expect(parsed.questions.size).to eq(1)
    expect(parsed.questions.first.name).to eq(:purpose_of_visit?)
    expect(parsed.questions.first.title).to eq("What are you coming to the UK to do?")
  end

  it "extracts list of outcome nodes" do
    expect(parsed.outcomes.map(&:name)).to eq([:outcome_work, :outcome_study])
  end

  describe "extracting outcomes" do
    subject(:outcome) { parsed.outcomes.first }

    it "extracts title" do
      expect(outcome.title).to eq("You'll need a visa to come to the UK to work or do business")
    end

    it "extracts body" do
      expect(outcome.body).to eq("The visa you apply for depends on your circumstances.\n")
    end
  end

  describe "extracting a multiple choice question node" do
    subject(:question) { parsed.questions.first }

    it { should be_a(Model::MultipleChoiceQuestion) }

    it "should list options with name and label" do
      expect(question.options).to eq([
        Model::Option.new(:work, "Work or business"),
        Model::Option.new(:study, "Study", :outcome_study)
      ])
    end

    it "should extract next node logic from options" do
      expect(question.next_node_rules.size).to eq(1)

      rule = question.next_node_rules.first
      expect(rule.next_node).to eq(:outcome_study)
      expect(rule.predicate).to eq(Predicate::Equality.new("purpose_of_visit", "study"))
    end
  end
end
