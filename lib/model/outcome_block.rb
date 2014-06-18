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
        end.join("\n")
      end + render_predicate_definitions
    end

    def render_conditional_phrase(conditional_phrase)
      indicators = conditional_phrase.predicates.map { |predicate| footnote_reference(predicate) }.join
      phrase = lookup_phrase(conditional_phrase.phrase)

      in_paragraphs(strip_trailing_newline(phrase)).map do |paragraph|
        paragraph + indicators
      end.join("\n\n")
    end

    def render_predicate_definitions
      "\n" + @predicates.map.with_index do |predicate, i|
        footnote_reference(predicate) + ": " + unparse(predicate)
      end.join("\n") + "\n"
    end

    def unparse(predicate)
      Parser::Unparser.new.apply(predicate.sexp)
    end

    def strip_trailing_newline(text)
      text.gsub(/\n+\Z/, '')
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
      translations.get("#{phrase_name}")
    end

    def precalculation(name)
      precalculations.find {|p| p.name.to_s == name.to_s} || Precalculation.new(name, [])
    end
  end
end
