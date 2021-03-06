module Model
  Outcome = Struct.new(:name, :translations) do
    def title
      translations.get("#{name}.title")
    end

    def body
      translations.get("#{name}.body")
    end
  end
end
