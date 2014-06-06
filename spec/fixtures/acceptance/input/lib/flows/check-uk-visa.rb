status :published
satisfies_need "100982"

multiple_choice :purpose_of_visit? do
  option :work => :outcome_work
  option :study => :outcome_study
  option :tourism

  next_node_if(:outcome_tourism, responded_with("tourism"))
  next_node_if(:outcome_work, variable_matches(:work, "yes"))
end

outcome :outcome_work
outcome :outcome_study
outcome :outcome_tourism
