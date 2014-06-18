require 'parser/outcome_block_transform_chain'

describe Parser::OutcomeBlockTransformChain do
  let(:translations) { double(:translations, get: "no translation") }
  let(:transform_chain) { described_class.new(translations) }
  let(:sexp) { parse_ruby(ruby) }
  subject(:transformed) { transform_chain.apply(sexp) }

  context "an outcome with a block precalculating a phraselist" do
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

    context "a conditional phrase" do
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

    context "nested conditions for a phrase" do
      let(:predicate_sexp) { parse_ruby("predicate_name") }
      let(:predicate2_sexp) { parse_ruby("predicate_name2") }
      let(:ruby) { "outcome(:my_outcome) {
        precalculate(:precalculation) {
          phrases = PhraseList.new
          if predicate_name
            if predicate_name2
              phrases << :phrase
            end
          end
          phrases
        }
      }"}

      it "generates a precalculation with a conditional phrase model with a predicate" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase, [Predicate::Raw.new(predicate2_sexp), Predicate::Raw.new(predicate_sexp)])]
        )
      end
    end

    context "else-condition for a phrase" do
      let(:negated_predicate_sexp) { parse_ruby("!predicate_name") }
      let(:ruby) { "outcome(:my_outcome) {
        precalculate(:precalculation) {
          phrases = PhraseList.new
          if predicate_name
          else
            phrases << :phrase
          end
          phrases
        }
      }"}

      it "generates a precalculation with a conditional phrase model with a predicate" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase, [Predicate::Raw.new(negated_predicate_sexp)])]
        )
      end
    end

    context "elseif-condition for a phrase" do
      let(:negated_predicate_sexp) { parse_ruby("!predicate_name") }
      let(:predicate2_sexp) { parse_ruby("predicate2_name") }
      let(:ruby) { "outcome(:my_outcome) {
        precalculate(:precalculation) {
          phrases = PhraseList.new
          if predicate_name
          elsif predicate2_name
            phrases << :phrase
          end
          phrases
        }
      }"}

      it "generates a precalculation with a conditional phrase model with a predicate" do
        expect(transformed.precalculations.first.conditional_phrases).to eq(
          [Model::ConditionalPhrase.new(:phrase, [Predicate::Raw.new(predicate2_sexp), Predicate::Raw.new(negated_predicate_sexp)])]
        )
      end
    end
  end

  context "an outcome with two precalculation blocks" do
    let(:predicate1_sexp) { parse_ruby("predicate_name1") }
    let(:predicate2_sexp) { parse_ruby("predicate_name2") }

    let(:ruby) { "outcome(:my_outcome) {
      precalculate(:precalculation1) {
        phrases = PhraseList.new
        if predicate_name1
          phrases << :phrase1
        end
        phrases
      }
      precalculate(:precalculation2) {
        phrases = PhraseList.new
        if predicate_name2
          phrases << :phrase2
        end
        phrases
      }
    }"}

    it "generates a precalculation with a conditional phrase model with a predicate" do
      expect(transformed.precalculations).to eq(
        [
          Model::Precalculation.new(:precalculation1, [Model::ConditionalPhrase.new(:phrase1, [Predicate::Raw.new(predicate1_sexp)])] ),
          Model::Precalculation.new(:precalculation2, [Model::ConditionalPhrase.new(:phrase2, [Predicate::Raw.new(predicate2_sexp)])] )
        ]
      )
    end
  end

  context "unconditional phraselists" do
    let(:ruby) { "outcome(:my_outcome) {
      precalculate :precalculation do
        #{inner_ruby}
      end
    }"}

    context "a single unconditional phrase" do
      let(:inner_ruby) { "PhraseList.new(:my_phrase)" }

      it "returns a single precalculation with an unconditional phrase" do
        expect(transformed.precalculations).to eq(
          [Model::Precalculation.new(:precalculation, [Model::ConditionalPhrase.new(:my_phrase, [])])]
        )
      end
    end

    context "a single conditional phrase" do
      let(:predicate) { "my_pred"}
      let(:predicate_sexp) { parse_ruby(predicate) }
      let(:inner_ruby) { "if #{predicate}
        PhraseList.new(:my_phrase)
      end" }

      it "returns a single precalculation with an conditional phrase" do
        expect(transformed.precalculations).to eq(
          [Model::Precalculation.new(:precalculation, [Model::ConditionalPhrase.new(:my_phrase, [Predicate::Raw.new(predicate_sexp)])])]
        )
      end
    end

    context "multiple conditional phrases" do
      let(:predicate) { "my_pred"}
      let(:predicate_sexp) { parse_ruby(predicate) }
      let(:negated_predicate_sexp) { parse_ruby("!#{predicate}") }
      let(:inner_ruby) { <<-RUBY
        if #{predicate}
          PhraseList.new(:true_phrase)
        else
          PhraseList.new(:false_phrase)
        end
        RUBY
      }

      it "returns a single precalculation with an conditional phrase" do
        expect(transformed.precalculations).to eq(
          [
            Model::Precalculation.new(:precalculation, [
              Model::ConditionalPhrase.new(:true_phrase, [Predicate::Raw.new(predicate_sexp)]),
              Model::ConditionalPhrase.new(:false_phrase, [Predicate::Raw.new(negated_predicate_sexp)])
            ])
          ]
        )
      end
    end
  end

end
