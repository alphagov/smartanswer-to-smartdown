module Model
  class OnConditionRule < Struct.new(:predicate, :inner_rules); end
end
