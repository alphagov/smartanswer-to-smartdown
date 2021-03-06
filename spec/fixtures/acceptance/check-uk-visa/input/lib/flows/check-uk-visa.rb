status :published
satisfies_need "100982"

multiple_choice :purpose_of_visit? do
  option :work => :outcome_work
  option :study => :outcome_study
  option :tourism

  next_node_if(:outcome_tourism, responded_with("tourism"))
  next_node_if(:outcome_work, variable_matches(:work, "yes"))
  on_condition(responded_with(%w{tourism})) do
    next_node_if(:outcome_study, variable_matches(:work, "no"))
  end
end

outcome :outcome_work do
  precalculate :if_turkey do
    if purpose_of_visit == "work_in_turkey"
      PhraseList.new :you_may_work
    end
  end
end

outcome :outcome_study
outcome :outcome_tourism
