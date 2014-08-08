# Smartanswer to smartdown converter

This is an experimental (work-in-progress) tool for converting
[smartanswers](https://github.com/alphagov/smart-answers) into
[smartdown](https://github.com/alphagov/smartdown).

In works by parsing the ruby code of the smart-answer flow, building a model
of it and then generating the equivalent smartdown.

Note that it only works with the 'new-style' next node rules in smart answers
defined using the `next_node_if` and `on_condition` methods. Some smart
answers have not yet been converted to this new style, although a rough pass
at this was made on the [static-next-node-all](https://github.com/alphagov/smart-answers/tree/static-next-node-all) branch.

To run the converter:

```
$ ./bin/smartanswer-to-smartdown ../smart-answers/lib/flows/student-finance-forms.rb student-finance-forms-smartdown
```

This will create a new folder named `student-finance-forms-smartdown`
containing the smartdown files.

## Known issues/limitations

currently silently ignores `next_node` statements, even unconditional ones.
These are sometimes used in 'new-style' smartanswers to declare the 'default'
in a sequence of rules. To fix this, you'd need to add a new transform to
`NextNodeRulesTransform`.

Not all permutations of phrase lists are handled.

