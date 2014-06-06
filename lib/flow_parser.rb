require 'ruby_parser'
require 'sexp_path'

require 'translations'

module SexpPathDsl
  def Q?(&block)
    SexpPath::SexpQueryBuilder.do(&block)
  end
end

class FlowParser
  include SexpPathDsl

  def initialize(name, ruby, yaml)
    @name = name
    @ruby = ruby
    @yaml = yaml
  end

  def self.parse(flow_name, ruby, yaml)
    FlowParser.new(flow_name, ruby, yaml)
  end

  def questions
    @questions ||= extract_questions
  end

  def extract_questions
    (parse_tree / question_query).map do |match|
      Question.new(translations, match["method_name"], match["method_args"], match["body"])
    end
  end

  def question_query
    Q? {
      s(:iter,
        s(:call, nil, m(%r{#{QUESTION_METHODS.join("|")}}) % 'method_name', ___ % "method_args"),
        s(:args, ___ % "block_args"),
        ___ % "body")
    }
  end

  def coversheet
    {
      title: translations.get("title"),
      start_with: questions.first.name,
      satisfies_need: satisfies_need,
      meta_description: meta_description
    }
  end

  def satisfies_need
    match = find_one(Q? { s(:call, nil, :satisfies_need, s(:str, atom % "need_id")) })
    match && match['need_id']
  end

  def meta_description
    translations.get("meta.description")
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

  def find(query)
    parse_tree / query
  end

  def find_one(query)
    matches = parse_tree / query
    matches.any? ? matches.first : nil
  end

  def parse_tree
    @parse_tree ||= RubyParser.for_current_ruby.parse(@ruby)
  end

private
  def translations
    @translations ||= Translations.new(@name, @yaml)
  end

  class Question
    include SexpPathDsl

    attr_reader :question_type, :name, :args, :body, :translations

    private :translations

    def initialize(translations, question_type, args, body)
      @translations = translations
      @question_type = question_type
      @name, @args = parse_args(args)
      @body = body
    end

    def title
      translations.get("#{@name}.title")
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
end
