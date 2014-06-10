require "model/question"

module Model
  class MultipleChoiceQuestion < Model::Question
    attr_reader :options

    def initialize(options, *super_args)
      super(*super_args)
      @options = options
    end
  end
end
