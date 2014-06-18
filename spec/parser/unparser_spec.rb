require 'parser/unparser'

describe Parser::Unparser do
  examples = [
    "true",
    "false",
    "1",
    "foo",
    "foo == 1",
    "foo == '1'",
    '"#{a}"',
    'a.b',
    'a.b(1)',
    "a.b('a')"
  ]

  examples.each do |example|
    it "can round-trip '#{example}'" do
      unparsed = described_class.new.apply(parse_ruby(example))
      expect(unparsed).to eq(example)
    end
  end
end
