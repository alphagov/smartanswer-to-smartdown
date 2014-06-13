module Model
  ConditionalPhrase = Struct.new(:phrase, :predicates) do
    def initialize(phrase, predicates = [])
      super(phrase, predicates)
    end
  end
end
