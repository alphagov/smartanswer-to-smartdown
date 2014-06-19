require 'model/conditional_phrase'

module Parser
  class PhrasePushTransform < Parser::Transform
    def pattern
      Q? {
        s(:call, s(:lvar, :phrases), :<<,
          any(
            s(:lit, atom % "phrase"),
            s(:dsym, ___ % "dsym_body")
          )
        )
      }
    end

    def transform(sexp, match)
      Model::ConditionalPhrase.new(match["phrase"] || match["dsym_body"])
    end
  end
end
