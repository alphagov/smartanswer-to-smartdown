require 'parser/outcome_block_transform'

describe Parser::OutcomeBlockTransform do
  let(:sexp) { parse_ruby(ruby) }
  let(:translations) { double(:translations, get: "no translation") }
  subject(:transform) { described_class.new(translations) }

  context "an outcome with an empty block" do
    let(:ruby) { "outcome(:my_outcome) {}" }

    it "accepts it" do
      expect(transform.match?(sexp)).to eq(true)
    end

    it "transforms to a Model::OutcomeBlock" do
      expect(transform.apply(sexp)).to eq(
        Model::OutcomeBlock.new(:my_outcome, translations, [])
      )
    end
  end
end
