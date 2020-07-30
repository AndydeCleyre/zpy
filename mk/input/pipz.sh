#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
. "${gitroot}/mk/input/common.sh"

printf '%s\n' \
    "Recommended record command: width=112 ./mk/svg/demo.sh" \
    "Beginning demo input for pipz in 10 seconds." \
    "Focus the recording terminal, or abort now with ctrl-C"
sleep 10

enter
t 'pipz '; tab 4; t ' httpi'; tab; t youtu; tab 5; enter 2; sleep 20; tab 2; enter; sleep 5
t 'pipz l'; tab; enter; sleep 5
t 'pipz l'; tab; t h; tab; enter; sleep 5
t 'pipz up'; tab; enter; down; enter; sleep 10
t 'pipz up'; tab; t -; tab 3; enter 2
