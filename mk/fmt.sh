#!/bin/sh -e

cd "$(git -C "$(dirname -- "$0")" rev-parse --show-toplevel)"

if [ "$1" ]; then
  printf '%s\n' 'Check mk scripts with shellcheck' 'Args: None' 1>&2
  exit 1
fi

shellcheck mk/*.sh mk/*/*.sh
