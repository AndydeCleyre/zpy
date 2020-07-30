#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
. "${gitroot}/mk/input/common.sh"

printf '%s\n' \
    "Recommended record command: width=89 ./mk/svg/demo.sh" \
    "Beginning demo input for preview in 10 seconds." \
    "Focus the recording terminal, or abort now with ctrl-C"
sleep 10

enter
t 'mkdir project'; enter; t 'cd proj'; tab; enter
t 'envin'; enter; sleep 10
t 'pipac httpx'; enter; sleep 10
t 'pipac -'; tab 3; enter; tab 4; enter; t 'pytes'; tab 3; enter 2; sleep 10
t 'pips'; enter
