module Model
  OutcomeBlock = Struct.new(:name, :translations, :precalculations) do
    def title
      translations.get("#{name}.title")
    end

    def body
      translations.get("#{name}.body")
    end
  end
end
