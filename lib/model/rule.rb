module Model
  class Rule < Struct.new(:next_node, :predicate)
  end
end
