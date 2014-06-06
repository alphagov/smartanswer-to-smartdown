require 'translations'

describe Translations do
  let(:fixtures) { Pathname.new("fixtures/unit").expand_path(File.dirname(__FILE__)) }
  let(:flow_yml_filename) { fixtures + "example.yml" }

  subject(:translations) {
    Translations.new(flow_yml_filename)
  }

  it "can get a translation string by dotted path" do
    expect(translations.get("title")).to eq "Check if you need a UK visa"
  end
end
