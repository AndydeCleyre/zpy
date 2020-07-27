#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
. "${gitroot}/mk/input/common.sh"

printf '%s\n' \
    "Beginning demo input for preview in 10 seconds." \
    "Focus the recording terminal, or abort now with ctrl-C"
sleep 10

enter
t 'mkdir project'; enter; t 'cd proj'; tab; enter
t 'envin'; enter; sleep 7
t 'pipac httpx'; enter; sleep 3
t 'pipac -'; tab 3; enter; tab 2; enter; t 'ward'; enter; sleep 4
t 'pips'; enter; sleep 6
