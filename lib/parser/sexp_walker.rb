module Parser
  module SexpWalker
    def self.walk_including_root(sexp, &block)
      walk(sexp, &block)
      block.call(sexp)
    end

    def self.walk(sexp, &block)
      sexp.each do |sub_sexp|
        walk(sub_sexp, &block) if sub_sexp.is_a?(Sexp)
        block.call(sub_sexp)
      end
    end

    def self.select(sexp, &block)
      collection = []
      walk(sexp) { |elem|
        collection << elem if yield(elem)
      }
      collection
    end

    def self.select_type(sexp, *types)
      select(sexp) { |elem| types.any? {|t| elem.is_a?(t)} }
    end
  end
end

