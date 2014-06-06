require 'translations'

describe Translations do
  let(:fixtures) { Pathname.new("fixtures/unit").expand_path(File.dirname(__FILE__)) }
  let(:flow_name) { "example" }
  let(:flow_yml) { File.read(fixtures + "#{flow_name}.yml") }

  subject(:translations) {
    Translations.new(flow_name, flow_yml)
  }

  it "can get a translation string by dotted path" do
    expect(translations.get("title")).to eq "Check if you need a UK visa"
  end
end
