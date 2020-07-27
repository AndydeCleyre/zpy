#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
. "${gitroot}/mk/input/common.sh"

printf '%s\n' \
    "Beginning demo input for pipz in 10 seconds." \
    "Focus the recording terminal, or abort now with ctrl-C"
sleep 10

enter
t 'pipz '; tab 4; t ' httpi'; tab; t youtu; tab 5; enter 2
sleep 17; tab 2; enter
t 'pipz l'; tab; enter
t 'pipz l'; tab; t h; tab; enter
t 'pipz up'; tab; enter; down; enter
# #
sleep 8;
t 'pipz up';
tab;
t -;
tab 3;
enter 2
