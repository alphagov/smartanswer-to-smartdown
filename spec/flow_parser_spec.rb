require 'pathname'
require 'flow_parser'

describe "FlowParser" do
  let(:fixtures) { Pathname.new("fixtures/unit").expand_path(File.dirname(__FILE__)) }
  let(:flow) { File.read(fixtures + "example.rb") }
  let(:flow_yml) { File.read(fixtures + "example.yml") }

  subject(:parsed) {
    FlowParser.parse(flow, flow_yml)
  }

  it "extracts list of question nodes" do
    expect(parsed.questions.size).to eq(1)
    expect(parsed.questions.first.name).to eq(:purpose_of_visit?)
    expect(parsed.questions.first.title).to eq(:purpose_of_visit?)
  end

  it "extracts the coversheet metadata" do
    pending
    expect(parsed.coversheet).to eq(
      title: "Check if you need a UK visa",
      meta_description: "You may need a visa to come to the UK to visit, study or work.",
      satisfies_need: "100982",
      start_with: "what_passport_do_you_have?"
    )
  end
end
