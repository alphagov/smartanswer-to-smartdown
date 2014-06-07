module Predicate
  class Conjunction
    attr_reader :predicates

    def initialize(*predicates)
      @predicates = predicates
    end

    def ==(other)
      other.is_a?(self.class) && self.predicates == other.predicates
    end

    def inspect
      "Conjunction<" + @predicates.map(&:inspect).join(" && ") + ">"
    end
  end
end
