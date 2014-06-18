require 'ruby_parser'
require 'sexp_path'

require 'parser/translations'
require 'parser/question'
require 'parser/outcome_block_transform'
require 'parser/outcome_transform'
require 'sexp_path_dsl'

module Parser
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
      transform.select {|n| n.is_a?(Model::Question) }
    end

    def outcomes
      transform.select {|n|
        [Model::Outcome, Model::OutcomeBlock].any? { |k|
          n.is_a?(k)
        }
      }
    end

    def coversheet
      {
        start_with: questions.first.name,
        satisfies_need: satisfies_need,
        meta_description: meta_description
      }.reject { |k,v| v.nil? }
    end

    def title
      translations.get("title")
    end

    def body
      translations.get("body")
    end

    def satisfies_need
      match = find_one(Q? { s(:call, nil, :satisfies_need, s(:str, atom % "need_id")) })
      match && match['need_id']
    end

    def meta_description
      translations.get("meta.description")
    end

  private

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

    def transform
      @transformed ||= (
        Parser::Question.new(translations) <<
          Parser::OutcomeBlockTransform.new(translations) <<
          Parser::OutcomeTransform.new(translations)
      ).apply(parse_tree)
    end

    def translations
      @translations ||= Translations.new(@name, @yaml)
    end
  end
end
