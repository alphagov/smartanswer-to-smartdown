require 'model/question'

describe Model::Question do
  let(:translations) { double("translations", get: "My title") }
  let(:name) { :my_question? }
  let(:type) { :date_question }
  let(:body) { double(:body) }
  let(:args) { double(:args) }

  subject(:question) { described_class.new(type, name, args, body, translations)}

  describe "#title" do
    it "looks up the title using the translations" do
      expect(translations).to receive(:get).with("#{name}.title")
      expect(question.title).to eq("My title")
    end
  end

  describe "#response_variable_name" do
    subject { question.response_variable_name }

    context "name :my_question?" do
      let(:name) { :my_question? }
      it "should strip trailing '?' from name" do
        should eq("my_question")
      end
    end

    context "name :my_question" do
      let(:name) { :my_question }
      it "should use name unchanged" do
        should eq("my_question")
      end
    end
  end

  [:type, :name, :args, :body].each do |attr_name|
    it "should have #{attr_name} accessor" do
      expect(question.send(attr_name)).to eq(self.send(attr_name))
    end
  end
end
