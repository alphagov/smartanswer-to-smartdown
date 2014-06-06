require 'yaml'

class Translations
  def initialize(flow_name, yaml)
    @flow_name = flow_name
    @data = YAML.load(yaml)
    @language = @data.keys.first
  end

  def get(path)
    "flow.#{@flow_name}.#{path}".split(".").inject(@data[@language]) do |data, path_part|
      data && data.fetch(path_part, nil)
    end
  end
end
