require 'model/conditional_phrase'

module Parser
  class PhrasePushTransform < Parser::Transform
    def pattern
      Q? {
        s(:call, s(:lvar, :phrases), :<<, s(:lit, atom % "phrase"))
      }
    end

    def transform(sexp, match)
      Model::ConditionalPhrase.new(match["phrase"])
    end
  end
end
