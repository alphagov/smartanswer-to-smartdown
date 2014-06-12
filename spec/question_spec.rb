require 'pathname'
require 'parser/question'
require 'parser/translations'
require 'model/question'

describe Parser::Question do
  let(:flow_name) { "example" }
  let(:question_name) { :my_question }
  let(:translation_yaml) {
    {"en-GB" =>
      {"flow" =>
        {flow_name =>
          {question_name.to_s => {"title" => "My Question?"}}}}}.to_yaml
  }
  let(:translations) { Parser::Translations.new(flow_name, translation_yaml) }
  let(:sexp) { parse_ruby(ruby) }

  let(:question_parser) { Parser::Question.new(translations) }

  describe "#parse" do
    context "flow with two questions" do
      let(:ruby) { <<-RUBY
        value_question(:a) { }
        date_question(:b) { }
        RUBY
      }

      subject(:question) { question_parser.parse(sexp) }

      it "should extract the two questions" do
        should match([Model::Question, Model::Question])
      end

      describe "question types" do
        subject { question.map(&:type) }
        it { should eq [:value_question, :date_question] }
      end

      describe "question names" do
        subject { question.map(&:name) }
        it { should eq [:a, :b] }
      end
    end
  end

  [
    :country_select,
    :date_question,
    :optional_date,
    :value_question,
    :money_question,
    :salary_question,
    :checkbox_question
  ].each do |question_type|
    context question_type do
      let(:ruby) { "#{question_type}(:#{question_name}, :arg1) { do_stuff }" }

      subject(:question) { question_parser.parse(sexp) }

      it "should extract question type" do
        expect(question.type).to eq(question_type)
      end

      it "should extract question name" do
        expect(question.name).to eq(question_name)
      end

      it "should fetch title from translations" do
        expect(question.title).to eq("My Question?")
      end

      it "should extract question args" do
        expected_sexp = s(s(:lit, :arg1))
        expect(question.args).to eq(expected_sexp)
      end

      it "should extract question body" do
        expected_sexp = s(s(:call, nil, :do_stuff))
        expect(question.body).to eq(expected_sexp)
      end
    end
  end
end
