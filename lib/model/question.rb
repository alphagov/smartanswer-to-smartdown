require 'sexp_path_dsl'

module Model
  Question = Struct.new(:type, :name, :args, :body) do
    attr_reader :translations

    def initialize(*args, translations)
      super(*args)
      @translations = translations
    end

    def title
      translations.get("#{name}.title")
    end

    def response_variable_name
      name.to_s.gsub(/\?$/, '')
    end
  end
end
