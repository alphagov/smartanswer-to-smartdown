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

      eea_passport_phrase: |
        You have an EEA passport.
YAML
  }
  let(:translations) {
    Parser::Translations.new('example', translation_yaml)
  }
  let(:precalculations) {
    [
      Model::Precalculation.new(
        :phrase_list_placeholder,
        [
          Model::ConditionalPhrase.new(
            :eea_passport_phrase,
            Predicate::Raw.new(parse_ruby('eea_passport == true'))
          )
        ]
      )
    ]
  }

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
      expect(outcome_block.body.split("\n").last).to eq("[^1]: eea_passport == true")
    end
  end
end
