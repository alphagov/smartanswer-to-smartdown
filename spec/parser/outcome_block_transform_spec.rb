require 'parser/outcome_block_transform'
require 'parser/precalculation_transform'
require 'parser/conditional_transform'
require 'parser/phrase_transform'

describe Parser::OutcomeBlockTransform do

  let(:sexp) { parse_ruby(ruby) }

  let(:translations) { double(:translations, get: "no translation") }
  let(:transform) { described_class.new(translations) }
  subject(:transformed) { transform.apply(sexp) }

  context "an outcome with an empty block" do
    let(:ruby) {"outcome(:my_outcome) {}"}
    let(:expected) { Model::OutcomeBlock.new(:my_outcome, translations, []) }

    it "accepts it" do
      expect(transform.match?(sexp)).to eq(true)
    end

    it "transforms to a Model::OutcomeBlock" do
      expect(transform.apply(sexp)).to eq(expected)
    end
  end

  context "an outcome with a block precalculating a phraselist" do
    let(:precalculate_transform) { Parser::PrecalculationTransform.new }
    let(:phrase_transform) { Parser::PhraseTransform.new }
    let(:conditional_transform) { Parser::ConditionalTransform.new }
    let(:transform_chain) { phrase_transform << conditional_transform << precalculate_transform << transform }
    subject(:transformed) { transform_chain.apply(sexp) }

    context "the phraselist has one element" do
      let(:ruby) { "outcome(:my_outcome){
        precalculate(:precalculation){
          phrases = PhraseList.new
          phrases << :phrase
          phrases
        }
      }"}

      it "generates a precalculation model" do
        expect(transformed.precalculations).to match(
          [an_instance_of(Model::Precalculation)]
        )
      end

      it "generates a precalculation model with the right data" do
        expect(transformed.precalculations.first.name).to eq(:precalculation)
      end

      it "generates a precalculation with a conditional phrase model" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase)]
        )
      end
    end

    context "the phraselist has two elements" do
      let(:ruby) { "outcome(:my_outcome){
        precalculate(:precalculation){
          phrases = PhraseList.new
          phrases << :phrase
          phrases << :other_phrase
          phrases
        }
      }"}
      it "generates a precalculation with two conditional phrase model" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase), Model::ConditionalPhrase.new(:other_phrase)]
         )
      end
    end

    context "the phraselist has an element with a predicate" do
      let(:predicate_sexp) {
        parse_ruby("predicate_name")
      }
      let(:ruby) { "outcome(:my_outcome){
        precalculate(:precalculation){
          phrases = PhraseList.new
          if predicate_name
            phrases << :phrase
          end
          phrases
        }
      }"}

      it "generates a precalculation with a conditional phrase model with a predicate" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase, [Predicate::Raw.new(predicate_sexp)])]
        )
      end
    end


    context "the phraselist has an element with a predicate" do
      let(:predicate_sexp) {
        parse_ruby("predicate_name")
      }
      let(:ruby) { "outcome(:my_outcome){
        precalculate(:precalculation){
          phrases = PhraseList.new
          if predicate_name
            phrases << :phrase
          end
          if predicate_name2
            phrases << :phrase2
          end
          phrases
        }
      }"}

      it "generates a precalculation with a conditional phrase model with a predicate" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase, [Predicate::Raw.new(predicate_sexp)])]
        )
      end
    end
  end
end
