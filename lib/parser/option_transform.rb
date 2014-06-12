module Parser
  class OptionTransform < Parser::Transform
    attr_reader :translations

    def initialize(translations)
      @translations = translations
    end

    def pattern
      Q? {
        s(:call, nil, :option,
          any(
            s(:lit, atom % "option_name"),
            s(:hash, s(:lit, atom % "option_name"), s(:lit, atom % "next_node"))
          ) % "option_arg"
        )
      }
    end

    def transform(sexp, match)
      next_node = if (match["option_arg"] / Q? { s(:hash, s(:lit, _), s(:lit, _)) }).any?
        match["next_node"]
      else
        nil
      end
      UnboundOption.new(
        match["option_name"],
        next_node
      )
    end

    class UnboundOption < Struct.new(:name, :next_node); end
  end
end
