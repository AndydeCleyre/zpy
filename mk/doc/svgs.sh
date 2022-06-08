#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "${gitroot}/doc/dot"

for dot in *.dot; do
  svg="$(printf '%s\n' "$dot" | sed -E 's/\.dot$/.svg/')"
  dot -Tsvg "$dot" >"../src/img/${svg}"
done
