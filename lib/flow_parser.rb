require 'ruby_parser'
require 'sexp_path'

module SexpPathDsl
  def Q?(&block)
    SexpPath::SexpQueryBuilder.do(&block)
  end
end

class FlowParser
  attr_reader :questions

  include SexpPathDsl

  def initialize(ruby, yaml)
    @ruby = ruby
    @yaml = yaml
    parse!
  end

  def self.parse(ruby, yaml)
    FlowParser.new(ruby, yaml)
  end

  def coversheet
  end

  QUESTION_METHODS = [
    :multiple_choice,
    :country_select,
    :date_question,
    :optional_date,
    :value_question,
    :money_question,
    :salary_question,
    :checkbox_question
  ]

private
  def parse!
    parsed = RubyParser.for_current_ruby.parse(@ruby)
    translations = Translations.new(@yaml)
    @questions = extract_questions(parsed, translations)
  end

  def extract_questions(parsed)
    query = Q? {
      s(:iter,
        s(:call, nil, m(%r{#{QUESTION_METHODS.join("|")}}) % 'method_name', ___ % "method_args"),
        s(:args, ___ % "block_args"),
        ___ % "body")
    }
    (parsed / query).map {|sexp_match|
      Question.new(sexp_match["method_name"], sexp_match["method_args"], sexp_match["body"])}
  end

  class Question
    include SexpPathDsl

    attr_reader :question_type, :name, :args, :body

    def initialize(question_type, args, body)
      @question_type = question_type
      @name, @args = parse_args(args)
      @body = body
    end

    def title
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

  class Translations
    def initialize(yaml)
    end
  end
end
