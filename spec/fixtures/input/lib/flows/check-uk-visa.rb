status :published
satisfies_need "100982"

multiple_choice :purpose_of_visit? do
  option :work => :outcome_work
  option :study => :outcome_study
end

outcome :outcome_work
outcome :outcome_study
