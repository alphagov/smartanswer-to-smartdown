require 'parser/sexp_walker'

describe Parser::SexpWalker do
  describe "#walk" do
    let(:sexp) { s(:a, s(:b)) }

    it "iterates over a sexp depth-first yielding each node of the sexp in turn" do
      expect {|probe| described_class.walk(sexp, &probe) }.to yield_successive_args(
        :a,
        :b,
        s(:b)
      )
    end
  end

  describe "#walk_including_root" do
    let(:sexp) { s(:a, s(:b)) }

    it "iterates over a sexp depth-first yielding each node of the sexp in turn, and finally yielding the root node" do
      expect {|probe| described_class.walk_including_root(sexp, &probe) }.to yield_successive_args(
        :a,
        :b,
        s(:b),
        s(:a, s(:b))
      )
    end
  end

  describe "#select" do
    let(:sexp) { s(:a, s(:b)) }
    subject { described_class.select(sexp, &predicate) }

    context "true predicate" do
      let(:predicate) { ->(_) { true } }

      it "returns an array of all elements" do
        should eq(
          [
            :a,
            :b,
            s(:b)
          ]
        )
      end
    end

    context "false predicate" do
      let(:predicate) { ->(_) { false } }
      it "returns an empty array" do
        should eq([])
      end
    end

    context "selective predicate" do
      let(:predicate) { ->(elem) { elem == :b } }
      it "returns an empty array" do
        should eq([:b])
      end
    end
  end

  describe "#select_type" do
    let(:sexp) { s(1, s(:b, "c")) }
    subject { described_class.select_type(sexp, *type) }

    context "filtering for String type" do
      let(:type) { String }
      it "should return only the strings" do
        should eq(["c"])
      end
    end
  end
end
