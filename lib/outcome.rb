class Outcome
  attr_reader :name, :translations

  def initialize(translations, name)
    @translations = translations
    @name = name
  end

  def title
    translations.get("#{name}.title")
  end

  def body
    translations.get("#{name}.body")
  end
end
