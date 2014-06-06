require 'pathname'
require 'flow_parser'

describe "FlowParser" do
  let(:fixtures) { Pathname.new("fixtures/unit").expand_path(File.dirname(__FILE__)) }
  let(:flow_name) { "example" }
  let(:flow_ruby) { File.read(fixtures + "#{flow_name}.rb") }
  let(:flow_yml) { File.read(fixtures + "#{flow_name}.yml") }

  subject(:parsed) {
    FlowParser.parse(flow_name, flow_ruby, flow_yml)
  }

  it "extracts list of question nodes" do
    expect(parsed.questions.size).to eq(1)
    expect(parsed.questions.first.name).to eq(:purpose_of_visit?)
    expect(parsed.questions.first.title).to eq("What are you coming to the UK to do?")
  end

  it "extracts the coversheet metadata" do
    expect(parsed.coversheet).to eq(
      title: "Check if you need a UK visa",
      meta_description: "You may need a visa to come to the UK to visit, study or work.",
      satisfies_need: "100982",
      start_with: :purpose_of_visit?
    )
  end
end
