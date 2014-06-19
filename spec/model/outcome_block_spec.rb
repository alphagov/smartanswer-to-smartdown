require 'model/outcome_block'
require 'model/precalculation'
require 'model/conditional_phrase'
require 'predicate/raw'
require 'parser/translations'

describe Model::OutcomeBlock do
  let(:name) { :outcome_test }
  let(:translation_yaml) { <<-YAML
en-GB:
  flow:
    example:
      outcome_test:
        title: Test outcome
        body: |
          This is the body

          %{phrase_list_placeholder}

      phrases:
        eea_passport_phrase: |
          You have an EEA passport.
        eea_passport_phrase2: |
          You have two EEA passports.
YAML
  }
  let(:translations) { Parser::Translations.new('example', translation_yaml) }
  let(:conditional_phrases) {
    [
      Model::ConditionalPhrase.new(
        :eea_passport_phrase,
        [Predicate::Raw.new(parse_ruby('eea_passport == true'))]
      )
    ]
  }
  let(:precalculations) { [Model::Precalculation.new(:phrase_list_placeholder, conditional_phrases)] }

  subject(:outcome_block) { described_class.new(name, translations, precalculations) }

  describe "#title" do
    it "looks up the title using the translations" do
      expect(outcome_block.title).to eq("Test outcome")
    end
  end

  describe "#body" do
    it "looks up the body using the translations" do
      expect(outcome_block.body).to match(/This is the body/)
    end

    it "substitutes the precalculations in the body" do
      expect(outcome_block.body).to match(/^You have an EEA passport\./)
    end

    it "appends the conditional footnote indicator to the substituted phrase" do
      expect(outcome_block.body.split("\n")).to include("You have an EEA passport.[^1]")
    end

    it "appends the predicates as footnote definitions" do
      expect(outcome_block.body.split("\n").last).to eq("[^1]: (eea_passport == true)")
    end

    xcontext "multiple conditional phrases" do
      let(:conditional_phrases) {
        [
          Model::ConditionalPhrase.new(
            :eea_passport_phrase,
            [Predicate::Raw.new(parse_ruby('eea_passport == true'))]
          ),
          Model::ConditionalPhrase.new(
            :eea_passport_phrase2,
            [Predicate::Raw.new(parse_ruby('eea_passport == 2'))]
          )
        ]
      }

      it "appends the predicates as footnote definitions" do
        expect(outcome_block.body).to match("You have an EEA passport.[^1]\n\nYou have two EEA passports.[^2]\n\n")
      end
    end
  end
end
