require 'parser/transform'

describe Parser::Transform do
  describe "#apply" do
    it "should raise with abstract class error" do
      expect { Parser::Transform.new.apply(s()) }.to raise_error(/abstract/i)
    end
  end

  describe "pattern-based transformer" do
    class PatternBasedTransformer < Parser::Transform
      def pattern
        Q? { s(atom, atom % "r") }
      end

      def transform(elem)
        "T(#{elem.map(&:to_s).join(',')})"
      end
    end

    subject(:transformer) { PatternBasedTransformer.new }

    it "should traverse the s-expression depth first applying itself if a match is found" do
      expect(transformer.apply(s(s(:a, :b), :c))).to eq("T(T(a,b),c)")
    end

    describe "capturing match data" do
      class SpyOnMatchData < Parser::Transform
        attr_reader :matches

        def initialize
          @matches = []
        end

        def pattern
          Q? { s(atom % "l") }
        end

        def transform(elem, match)
          @matches << match
        end
      end

      subject(:transformer) { SpyOnMatchData.new }

      it "should store match data in instance variable" do
        transformer.apply(s(:a))

        expect(transformer.matches).to eq([{'l' => :a}])
      end
    end
  end

  describe "raw match transformer" do
    class RawMatchTransformer < Parser::Transform
      def match?(elem)
        if elem.is_a?(Sexp) && elem.first == :a
          @match_data = { a: "yes" }
          true
        end
      end

      def transform(elem)
        @match_data[:a]
      end
    end

    let(:transformer) { RawMatchTransformer.new }

    it "should transform matched elements" do
      expect(transformer.apply(s(:a, :b))).to eq("yes")
      expect(transformer.apply(s(:b, :b))).to eq(s(:b, :b))
    end
  end

  describe "chaining using #<<" do
    let(:t1) {
      Class.new(Parser::Transform) do
        def match?(elem)
          elem.is_a?(Sexp) && elem.first == :inner
        end

        def transform(elem)
          :result_of_t1
        end
      end.new
    }
    let(:t2) {
      Class.new(Parser::Transform) do
        def match?(elem)
          elem.is_a?(Sexp) && elem.first == :result_of_t1
        end

        def transform(elem)
          :result_of_t2
        end
      end.new
    }
    let(:sexp) { s(s(:inner)) }

    it "should apply chained transforms in order" do
      expect((t1 << t2).apply(sexp)).to eq(:result_of_t2)
      expect((t2 << t1).apply(sexp)).to eq(s(:result_of_t1))
    end

    it "can repeatedly chain" do
      t = t1 << t1 << t2
      expect(t.apply(sexp)).to eq(:result_of_t2)
    end
  end
end
