# encoding: utf-8
require 'pathname'
require 'fileutils'
require 'parser/flow_parser'
require 'erb'

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
    render_template("coversheet", binding)
  end

  def generate_question(question)
    template_name = underscore(question.class.to_s.split("::").last)
    render_template(template_name, binding)
  end

  def underscore(camel_case_text)
    camel_case_text.gsub(/([a-z]|^)([A-Z])/) do
      $1.empty? ? $2.downcase : "#{$1}_#{$2.downcase}"
    end
  end

  def generate_outcome(outcome)
    l = []
    l << "# #{outcome.title}"
    l << ""
    l << outcome.body
    l.join("\n")
  end

  def render_rule(question, rule, indent = "")
    case rule
    when Model::OnConditionRule
      lines = ["#{indent}* #{render_predicate(question, rule.predicate)}"] +
        rule.inner_rules.map {|inner| render_rule(question, inner, indent + "  ")}
      lines.join("\n")
    when Model::Rule
      "#{indent}* #{render_predicate(question, rule.predicate)} => #{rule.next_node}"
    else
      raise rule
    end
  end

  def render_predicate(question, predicate)
    case predicate
    when Predicate::Equality
      "#{predicate.variable_name || question.response_variable_name} is '#{predicate.expected_value}'"
    when Predicate::SetInclusion
      "#{predicate.variable_name || question.response_variable_name} in {#{predicate.expected_values.join(" ")}}"
    else
      "???"
    end
  end

private
  def render_template(template_name, binding)
    path = File.expand_path("templates/#{template_name}.erb", File.dirname(__FILE__))
    ERB.new(File.read(path), nil, '%').result(binding)
  end

  def write_file(filename, &block)
    FileUtils.mkdir_p(output_path + File.dirname(filename))
    File.open(output_path + filename, "w") do |f|
      f.write(yield)
    end
  end

  def flow
    @flow ||= Parser::FlowParser.new(flow_name, flow_ruby, flow_yaml)
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
