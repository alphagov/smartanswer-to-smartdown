require 'parser/unparser'

describe Parser::Unparser do
  it "unparses some ruby code" do
    sexp = parse_ruby("a.b")
    expect(described_class.unparse(sexp)).to eq "a.b"
  end

  it "does not destroy the input" do
    sexp = parse_ruby("a.b")
    described_class.unparse(sexp)
    expect(sexp).to eq(parse_ruby("a.b"))
  end
end
