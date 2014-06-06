require 'sexp_path_dsl'

class Question
  include SexpPathDsl

  attr_reader :name, :args, :body, :translations

  private :translations

  def initialize(translations, args, body)
    @translations = translations
    @name, @args = parse_args(args)
    @body = body
  end

  def title
    translations.get("#{name}.title")
  end

  def response_variable_name
    name.to_s.gsub(/\?$/, '')
  end

private
  def parse_args(args)
    match = (args / Q? { s( s(:lit, atom % "name"), ___ % "extra_args") })
    [
      match.first["name"],
      match.first["extra_args"]
    ]
  end
end
