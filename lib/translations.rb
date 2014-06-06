require 'yaml'

class Translations
  def initialize(filename)
    @data = YAML.load_file(filename)
    @language = @data.keys.first
  end

  def get(path)
    path.split(".").inject(@data[@language]) do |data, path_part|
      data[path_part]
    end
  end
end
