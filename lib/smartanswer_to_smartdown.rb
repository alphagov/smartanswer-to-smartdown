# encoding: utf-8
require 'pathname'
require 'fileutils'
require 'flow_parser'

class SmartanswerToSmartdown
  attr_reader :source_path, :output_path

  def initialize(source_path, output_path)
    @source_path = source_path
    @output_path = Pathname.new(output_path)
  end

  def call
    write_file("#{flow_name}.txt") { generate_coversheet }

    flow.questions.each do |question|
      write_file("#{question.response_variable_name}.txt") { generate_question(question) }
    end

    flow.outcomes.each do |outcome|
      filename = outcome.name.to_s.gsub(/^outcome_/, '')

      write_file("outcomes/#{filename}.txt") { generate_outcome(outcome) }
    end
  end

  def generate_coversheet
    lines = []
    flow.coversheet.each do |key, value|
      lines << "#{key}: #{value}"
    end
    lines << ""
    lines << "# #{flow.title}"
    lines << ""
    lines << flow.body
    lines.join("\n")
  end

  def generate_question(question)
    l = []
    l << "# #{question.title}"
    l << ""
    question.options.each do |o|
      l << "* #{o.name}: #{o.label}"
    end
    l << ""
    l << "-----"
    l << ""
    l << "# Next node"
    l << ""
    question.next_node_rules.each do |rule|
      l << render_rule(rule)
    end
    l << ""
    l.join("\n")
  end

  def generate_outcome(outcome)
    l = []
    l << "# #{outcome.title}"
    l << ""
    l << outcome.body
    l.join("\n")
  end

  def render_rule(rule, indent = "")
    case rule
    when OnConditionRule
      lines = ["* #{render_predicate(rule.predicate)}"] +
        rule.inner_rules.map {|inner| render_rule(inner, indent + "  ")}
      lines.join("\n")
    when Rule
      "#{indent}* #{render_predicate(rule.predicate)} => #{rule.next_node}"
    else
      raise rule
    end
  end

  def render_predicate(predicate)
    "#{predicate.variable_name} is '#{predicate.expected_value}'"
  end

private
  def write_file(filename, &block)
    FileUtils.mkdir_p(output_path + File.dirname(filename))
    File.open(output_path + filename, "w") do |f|
      f.write(yield)
    end
  end

  def flow
    @flow ||= FlowParser.new(flow_name, flow_ruby, flow_yaml)
  end

  def flow_name
    File.basename(source_path, ".rb")
  end

  def flow_ruby
    File.read(source_path)
  end

  def flow_yaml
    File.read(yaml_path)
  end

  def yaml_path
    File.dirname(source_path) + "/locales/en/#{flow_name}.yml"
  end
end
