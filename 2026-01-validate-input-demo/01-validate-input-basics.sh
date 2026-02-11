#!/bin/bash
set -euo pipefail
source _helpers.sh

title "Validating arbitrary data" "Simon Baird"

show-msg "In this tutorial we'll introduce some basic Conforma concepts and
look at examples where Conforma is used to apply policy checks against
arbitrary input data."

show-msg $'We often use the `ec validate image` command, which fetches and
verifies an image\'s SLSA provenance attestations, then applies policy checks
against them. But Conforma can work just as well with any kind of input using
the `ec validate input` command, and in fact that is a useful way to
demonstrate some Conforma ideas and techniques.'

h1 "ec validate input"

show-msg $'Conforma can perform policy checks on arbitrary data with `ec
validate input`. Let\'s try an example.'

pause

show-msg "A simple data file:"

create-file input.yaml 'animals:
- name: Charlie
  species: dog
- name: Luna
  species: cat
'

show-yaml input.yaml

pause

show-msg "A minimal Conforma policy defined in Rego:"

mkdir -p no-cats

create-file no-cats/main.rego 'package main

# METADATA
# title: No cats
# description: Disallow felines.
# custom:
#   short_name: no_cats
#   solution: Ensure no cats are present in the animal list!
#
deny contains result if {
  some animal in input.animals
  animal.species == "cat"
  result := {"code":"main.no_cats", "msg":"No cats allowed!"}
}
'

show-rego no-cats/main.rego

pause

show-msg "To use that policy, Conforma needs a policy.yaml file specifying a source:"

create-file policy.yaml 'sources:
- policy:
  - ./no-cats
'

show-yaml policy.yaml

pause

show-msg "Now we can run Conforma like this:"

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml'

h1 "Using --info for more detailed output"

show-msg 'The metadata associated with the policy rule is important for
Conforma. Adding the `--info` flag will use the metadata to show more
details about the violation:'

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml --info'

h1 "Using --show-successes to show passing checks"

show-msg $'Let\'s "fix" the violation and run it again:'

show-then-run 'sed -i "s/cat/rabbit/" input.yaml'

show-yaml input.yaml -H5

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml --info'

pause

show-msg $'By default there\'s not much output on success, but we can add
the `--show-successes` flag to change that:'

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml --info --show-successes'

pause

show-msg "(Turn rabbits back into cats for the next step):"

show-then-run 'sed -i "s/rabbit/cat/" input.yaml'

h1 "Warnings"

show-msg 'We can use "warn" to produce a warning instead of a violation:'

append-file no-cats/main.rego '

# METADATA
# title: Charlie warning
# description: Charlie is a troublemaker!
# custom:
#   short_name: charlie_watch
#   solution: Keep a close eye on Charlie.
#
warn contains result if {
  some animal in input.animals
  animal.name == "Charlie"
  result := {"code":"main.charlie_watch", "msg":"Charlie is here"}
}
'

show-msg "(We'll append to the existing file here.)"

show-rego no-cats/main.rego -r16: '16,$p'

pause

show-msg "Notice we now see the warning in the output:"

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml --info --show-successes'

show-msg "Warnings are considered non-blocking."

h1 "Adding more detail to the violation reason"

sed -i 's/"No cats allowed!"/sprintf("A cat named %s was found!", [animal.name])/' no-cats/main.rego

show-msg "Rego is an expressive and capable language so we can easily add more detail to the violation reason. For example:"

show-rego no-cats/main.rego "-r10:14 -H13:13" "10,14p"

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml'

pause

show-msg 'If there are multiple cats, we now get multiple different violations:'

append-file input.yaml '- name: Fluffy
  species: cat
'

show-yaml input.yaml -H8:

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml'

show-msg $'That\'s about it for this lesson. Hopefully you now have a better
idea of what Conforma policies look like, and what kind of output Conforma
produces.'

show-msg $'Before we wrap this up let\'s look at two extra tips which should be
useful when integrating these kind of policy checks into a CI or build system:'

h1 "Machine readable output"

show-msg 'Text output is the default, but you can also output json or yaml,
which includes some additional information not included in the text output:'

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml --info --output json | fold -s -w 400'


h1 '"Strict" vs "non-strict"'

show-msg 'By default we produce a non-zero exit code if there are any
violations, which is useful to interrupt a script or a CI task. You can change
that behavior if you need to with `--strict=false:`'

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml > output.txt; echo "Exit code: $?"; head -3 output.txt'

pause-then-run 'ec validate input --file input.yaml --policy policy.yaml --strict=false > output.txt; echo "Exit code: $?"; head -3 output.txt'
