require 'parser/unparser'

module Model
  OutcomeBlock = Struct.new(:name, :translations, :precalculations) do
    def initialize(*args)
      @predicates = []
      super
    end

    def title
      translations.get("#{name}.title")
    end

    def body
      with_precalculations(raw_body)
    end

  private
    def raw_body
      translations.get("#{name}.body")
    end

    def with_precalculations(body)
      body.gsub(/%{([^}]+)}/) do
        precalculation($1).conditional_phrases.map do |conditional_phrase|
          render_conditional_phrase(conditional_phrase)
        end.join("\n\n")
      end
    end

    def render_conditional_phrase(conditional_phrase)
      clause = conditional_phrase.predicates.reverse.map { |predicate| unparse(predicate) }.join(" AND ")
      phrase = lookup_phrase(conditional_phrase.phrase)

      "$IF #{clause}\n\n#{strip_trailing_newline(phrase)}\n\n$ENDIF"
    end

    def unparse(predicate)
      Parser::Unparser.unparse(predicate.sexp)
    end

    def strip_trailing_newline(text)
      text.to_s.gsub(/\n+\Z/, '')
    end

    def in_paragraphs(markdown_text)
      markdown_text.split(/\n{2,}/)
    end

    def footnote_reference(predicate)
      "[^#{predicate_number(predicate)}]"
    end

    def predicate_number(predicate)
      if i = @predicates.find_index(predicate)
        i + 1
      else
        @predicates << predicate
        @predicates.size
      end
    end

    def lookup_phrase(phrase_name)
      translations.get("phrases.#{phrase_name}")
    end

    def precalculation(name)
      precalculations.find {|p| p.name.to_s == name.to_s} || Precalculation.new(name, [])
    end
  end
end
